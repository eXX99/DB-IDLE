import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class GameStorage {
  static const String _playerKey = 'db_player_state_v1';

  static Future<bool> savePlayer(PlayerCharacter player) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_playerKey, player.encodeState());
  }

  static Future<PlayerCharacter> loadOrCreatePlayer(String defaultName) async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_playerKey);

    if (rawData == null || rawData.isEmpty) {
      final initialPlayer = PlayerCharacter(
        name: defaultName,
        baseBp: 10,
        currentHp: 100,
        maxHp: 100,
        currentKi: 50,
        maxKi: 50,
        zeni: 0,
        knownTechniques: [
          Technique(
            id: 'kamehameha_basic',
            name: 'Kamehameha',
            kiCost: 20,
            damageMultiplier: 2.2,
            type: AttackType.ki,
            description: 'Klasyczna fala Ki Szkoły Żółwia.',
          ),
        ],
      );
      await savePlayer(initialPlayer);
      return initialPlayer;
    }

    try {
      return PlayerCharacter.decodeState(rawData);
    } catch (_) {
      return PlayerCharacter(name: defaultName);
    }
  }

  static Future<void> clearSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playerKey);
  }
}

class TrainingResult {
  final int bpGained;
  final int kiGained;

  TrainingResult({required this.bpGained, required this.kiGained});
}

class IncrementalTrainingEngine {
  static double _calculateMultiplier(PlayerCharacter player) {
    double mult = 1.0;
    player.equippedItems.forEach((_, item) {
      if (item != null) {
        mult *= item.trainingMultiplier;
      }
    });
    mult *= (1.0 + (player.zenkaiBoostCount * 0.15 * player.zenkaiMultiplierBonus));
    return mult;
  }

  static TrainingResult executePushUps(PlayerCharacter player) {
    final mult = _calculateMultiplier(player);
    final gainedBp = max(1, (1 * mult).round());

    player.baseBp += gainedBp;
    player.maxHp = 100 + (player.baseBp * 2);
    if (player.currentHp < player.maxHp) {
      player.currentHp = min(player.maxHp, player.currentHp + 5);
    }

    return TrainingResult(bpGained: gainedBp, kiGained: 0);
  }

  static TrainingResult executeMeditation(PlayerCharacter player) {
    final mult = _calculateMultiplier(player);
    final gainedKi = max(1, (1 * mult).round());

    player.maxKi += gainedKi;
    player.currentKi = min(player.maxKi, player.currentKi + (gainedKi * 2));

    return TrainingResult(bpGained: 0, kiGained: gainedKi);
  }

  static void processIdleTick(PlayerCharacter player, int elapsedSeconds) {
    if (elapsedSeconds <= 0) return;
    final mult = _calculateMultiplier(player);

    final passiveBp = ((0.5 * elapsedSeconds) * mult).round();
    player.baseBp += passiveBp;
    player.maxHp = 100 + (player.baseBp * 2);

    player.currentKi = min(player.maxKi, player.currentKi + (2 * elapsedSeconds));
    player.currentHp = min(player.maxHp, player.currentHp + (5 * elapsedSeconds));
  }
}

class TurnCombatLog {
  final String actorName;
  final String actionDescription;
  final int damageDealt;
  final bool isPlayerAction;

  TurnCombatLog({
    required this.actorName,
    required this.actionDescription,
    required this.damageDealt,
    required this.isPlayerAction,
  });
}

class BattleResolution {
  final bool isFinished;
  final bool playerWon;
  final int expGained;
  final int zeniGained;
  final bool triggeredZenkai;
  final int? awardedDragonBall;
  final List<TurnCombatLog> logs;

  BattleResolution({
    required this.isFinished,
    required this.playerWon,
    this.expGained = 0,
    this.zeniGained = 0,
    this.triggeredZenkai = false,
    this.awardedDragonBall,
    required this.logs,
  });
}

class BattleEngine {
  final PlayerCharacter player;
  final Enemy enemy;
  final Random _rng = Random();

  BattleEngine({required this.player, required this.enemy});

  BattleResolution executePlayerPhysicalAttack() {
    List<TurnCombatLog> logs = [];
    _processTurnUpkeep(logs);

    final baseDmg = (player.effectiveBp * 0.4).round();
    final variance = _rng.nextInt(max(1, (baseDmg * 0.2).round()));
    final totalDmg = max(1, baseDmg + variance);

    enemy.currentHp = max(0, enemy.currentHp - totalDmg);
    player.currentKi = min(player.maxKi, player.currentKi + 5);

    logs.add(TurnCombatLog(
      actorName: player.activeFusion?.name ?? player.name,
      actionDescription: 'wyprowadza niszczycielską serię ciosów wręcz (+5 Ki)',
      damageDealt: totalDmg,
      isPlayerAction: true,
    ));

    return _evaluateTurnOrCounter(logs, false);
  }

  BattleResolution executePlayerTechnique(Technique tech) {
    List<TurnCombatLog> logs = [];
    _processTurnUpkeep(logs);

    final actualCost = player.getActualKiCost(tech);

    if (player.currentKi < actualCost) {
      logs.add(TurnCombatLog(
        actorName: player.activeFusion?.name ?? player.name,
        actionDescription: 'brak energii Ki na ${tech.name} (wymaga $actualCost Ki)!',
        damageDealt: 0,
        isPlayerAction: true,
      ));
      return _evaluateTurnOrCounter(logs, false);
    }

    player.currentKi -= actualCost;
    bool skipEnemyCounter = false;

    if (tech.effect == TechniqueEffect.evasion) {
      skipEnemyCounter = true;
      final rawDmg = (player.effectiveBp * tech.damageMultiplier * 0.4).round();
      enemy.currentHp = max(0, enemy.currentHp - rawDmg);
      logs.add(TurnCombatLog(
        actorName: player.activeFusion?.name ?? player.name,
        actionDescription: 'używa ${tech.name}! Błyskawicznie omija ciosy przeciwnika!',
        damageDealt: rawDmg,
        isPlayerAction: true,
      ));
    } else {
      final rawDmg = (player.effectiveBp * tech.damageMultiplier * 0.5).round();
      final variance = _rng.nextInt(max(1, (rawDmg * 0.15).round()));
      final totalDmg = max(1, rawDmg + variance);
      enemy.currentHp = max(0, enemy.currentHp - totalDmg);

      logs.add(TurnCombatLog(
        actorName: player.activeFusion?.name ?? player.name,
        actionDescription: 'używa ${tech.name} (zużyto $actualCost Ki)',
        damageDealt: totalDmg,
        isPlayerAction: true,
      ));
    }

    return _evaluateTurnOrCounter(logs, skipEnemyCounter);
  }

  void _processTurnUpkeep(List<TurnCombatLog> logs) {
    if (player.activeForm != null && player.activeForm!.kiDrainPerTurn > 0) {
      player.currentKi -= player.activeForm!.kiDrainPerTurn;
      if (player.currentKi <= 0) {
        player.currentKi = 0;
        final formName = player.activeForm!.name;
        player.activeForm = null;
        logs.add(TurnCombatLog(
          actorName: player.name,
          actionDescription: 'traci całe zapasy Ki! Spadek z formy $formName!',
          damageDealt: 0,
          isPlayerAction: true,
        ));
      }
    }

    if (player.activeFusion != null && player.activeFusion!.durationTurns > 0) {
      player.fusionTurnsRemaining -= 1;
      if (player.fusionTurnsRemaining <= 0) {
        final fusionName = player.activeFusion!.name;
        player.activeFusion = null;
        player.fusionTurnsRemaining = 0;
        logs.add(TurnCombatLog(
          actorName: 'System',
          actionDescription: 'Czas fuzji $fusionName dobiegł końca! Rozdzielenie wojowników!',
          damageDealt: 0,
          isPlayerAction: true,
        ));
      }
    }
  }

  BattleResolution _evaluateTurnOrCounter(List<TurnCombatLog> logs, bool skipEnemyTurn) {
    if (enemy.isDead) {
      player.zeni += enemy.zeniReward;
      player.baseBp += enemy.expReward;

      int? droppedBall;
      if (enemy.dropsDragonBallNumber != null) {
        final ballNum = enemy.dropsDragonBallNumber!;
        if (!player.dragonBalls.contains(ballNum)) {
          player.dragonBalls.add(ballNum);
          player.dragonBalls.sort();
          droppedBall = ballNum;
        }
      }

      return BattleResolution(
        isFinished: true,
        playerWon: true,
        expGained: enemy.expReward,
        zeniGained: enemy.zeniReward,
        awardedDragonBall: droppedBall,
        logs: logs,
      );
    }

    if (skipEnemyTurn) {
      return BattleResolution(isFinished: false, playerWon: false, logs: logs);
    }

    final enemyDmgBase = (enemy.battlePower * 0.35).round();
    final enemyVariance = _rng.nextInt(max(1, (enemyDmgBase * 0.2).round()));
    int enemyFinalDmg = max(1, enemyDmgBase + enemyVariance);

    String enemyAction = 'kontratakuje potężnym ciosem!';
    if (enemy.specialMove != null && _rng.nextDouble() > 0.65) {
      enemyFinalDmg = (enemyFinalDmg * enemy.specialMove!.damageMultiplier).round();
      enemyAction = 'wyprowadza niszczycielskie: ${enemy.specialMove!.name}!';
    }

    player.currentHp = max(0, player.currentHp - enemyFinalDmg);

    logs.add(TurnCombatLog(
      actorName: enemy.name,
      actionDescription: enemyAction,
      damageDealt: enemyFinalDmg,
      isPlayerAction: false,
    ));

    if (player.currentHp <= 0) {
      player.zenkaiBoostCount += 1;
      final boostMultiplier = 1.0 + (0.25 * player.zenkaiMultiplierBonus);
      player.baseBp = (player.baseBp * boostMultiplier).round();
      player.currentHp = (player.maxHp * 0.5).round();
      player.activeForm = null;
      player.activeFusion = null;
      player.fusionTurnsRemaining = 0;

      return BattleResolution(
        isFinished: true,
        playerWon: false,
        triggeredZenkai: true,
        logs: logs,
      );
    }

    return BattleResolution(
      isFinished: false,
      playerWon: false,
      logs: logs,
    );
  }
}
