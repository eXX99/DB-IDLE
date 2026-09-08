import 'dart:convert';

enum ItemType { gi, weights, scouter, talisman, potara }
enum AttackType { physical, ki, utility }
enum TechniqueEffect { none, evasion, chargeUp, drainHp }
enum FusionType { dance, potara }

class FusionForm {
  final String id;
  final String name;
  final FusionType type;
  final double bpMultiplier;
  final int durationTurns;
  final int requiredBp;
  final int zeniCost;
  final String description;

  FusionForm({
    required this.id,
    required this.name,
    required this.type,
    required this.bpMultiplier,
    this.durationTurns = 0,
    required this.requiredBp,
    required this.zeniCost,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'bpMultiplier': bpMultiplier,
        'durationTurns': durationTurns,
        'requiredBp': requiredBp,
        'zeniCost': zeniCost,
        'description': description,
      };

  factory FusionForm.fromJson(Map<String, dynamic> json) => FusionForm(
        id: json['id'] as String,
        name: json['name'] as String,
        type: FusionType.values[json['type'] as int],
        bpMultiplier: (json['bpMultiplier'] as num).toDouble(),
        durationTurns: json['durationTurns'] as int? ?? 0,
        requiredBp: json['requiredBp'] as int? ?? 0,
        zeniCost: json['zeniCost'] as int? ?? 0,
        description: json['description'] as String? ?? '',
      );
}

class Technique {
  final String id;
  final String name;
  final int kiCost;
  final double damageMultiplier;
  final AttackType type;
  final TechniqueEffect effect;
  final int requiredBp;
  final int zeniCost;
  final String description;

  Technique({
    required this.id,
    required this.name,
    required this.kiCost,
    required this.damageMultiplier,
    required this.type,
    this.effect = TechniqueEffect.none,
    this.requiredBp = 0,
    this.zeniCost = 0,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kiCost': kiCost,
        'damageMultiplier': damageMultiplier,
        'type': type.index,
        'effect': effect.index,
        'requiredBp': requiredBp,
        'zeniCost': zeniCost,
        'description': description,
      };

  factory Technique.fromJson(Map<String, dynamic> json) => Technique(
        id: json['id'] as String,
        name: json['name'] as String,
        kiCost: json['kiCost'] as int,
        damageMultiplier: (json['damageMultiplier'] as num).toDouble(),
        type: AttackType.values[json['type'] as int],
        effect: json['effect'] != null
            ? TechniqueEffect.values[json['effect'] as int]
            : TechniqueEffect.none,
        requiredBp: json['requiredBp'] as int? ?? 0,
        zeniCost: json['zeniCost'] as int? ?? 0,
        description: json['description'] as String? ?? '',
      );
}

class Equipment {
  final String id;
  final String name;
  final ItemType type;
  final double bpMultiplierBonus;
  final int flatKiBonus;
  final double trainingMultiplier;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    this.bpMultiplierBonus = 0.0,
    this.flatKiBonus = 0,
    this.trainingMultiplier = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'bpMultiplierBonus': bpMultiplierBonus,
        'flatKiBonus': flatKiBonus,
        'trainingMultiplier': trainingMultiplier,
      };

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
        id: json['id'] as String,
        name: json['name'] as String,
        type: ItemType.values[json['type'] as int],
        bpMultiplierBonus: (json['bpMultiplierBonus'] as num).toDouble(),
        flatKiBonus: json['flatKiBonus'] as int,
        trainingMultiplier: (json['trainingMultiplier'] as num).toDouble(),
      );
}

class Transformation {
  final String id;
  final String name;
  final double multiplier;
  final int requiredBp;
  final int kiDrainPerTurn;

  Transformation({
    required this.id,
    required this.name,
    required this.multiplier,
    required this.requiredBp,
    this.kiDrainPerTurn = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'multiplier': multiplier,
        'requiredBp': requiredBp,
        'kiDrainPerTurn': kiDrainPerTurn,
      };

  factory Transformation.fromJson(Map<String, dynamic> json) => Transformation(
        id: json['id'] as String? ?? 'kaioken',
        name: json['name'] as String,
        multiplier: (json['multiplier'] as num).toDouble(),
        requiredBp: json['requiredBp'] as int,
        kiDrainPerTurn: json['kiDrainPerTurn'] as int,
      );
}

class Enemy {
  final String name;
  final int maxHp;
  int currentHp;
  final int battlePower;
  final int expReward;
  final int zeniReward;
  final Technique? specialMove;
  final int? dropsDragonBallNumber;

  Enemy({
    required this.name,
    required this.maxHp,
    required this.currentHp,
    required this.battlePower,
    required this.expReward,
    required this.zeniReward,
    this.specialMove,
    this.dropsDragonBallNumber,
  });

  bool get isDead => currentHp <= 0;

  Map<String, dynamic> toJson() => {
        'name': name,
        'maxHp': maxHp,
        'currentHp': currentHp,
        'battlePower': battlePower,
        'expReward': expReward,
        'zeniReward': zeniReward,
        'specialMove': specialMove?.toJson(),
        'dropsDragonBallNumber': dropsDragonBallNumber,
      };

  factory Enemy.fromJson(Map<String, dynamic> json) => Enemy(
        name: json['name'] as String,
        maxHp: json['maxHp'] as int,
        currentHp: json['currentHp'] as int,
        battlePower: json['battlePower'] as int,
        expReward: json['expReward'] as int,
        zeniReward: json['zeniReward'] as int,
        specialMove: json['specialMove'] != null
            ? Technique.fromJson(json['specialMove'] as Map<String, dynamic>)
            : null,
        dropsDragonBallNumber: json['dropsDragonBallNumber'] as int?,
      );
}

class LocationZone {
  final String id;
  final String name;
  final int requiredBp;
  final List<Enemy> possibleEnemies;
  final Enemy boss;

  LocationZone({
    required this.id,
    required this.name,
    required this.requiredBp,
    required this.possibleEnemies,
    required this.boss,
  });
}

class PlayerCharacter {
  String name;
  int baseBp;
  int currentHp;
  int maxHp;
  int currentKi;
  int maxKi;
  int zeni;
  int zenkaiBoostCount;
  double zenkaiMultiplierBonus;
  double permanentKiCostDiscount;
  int wishesGrantedCount;

  List<int> dragonBalls;
  List<Technique> knownTechniques;
  Map<ItemType, Equipment?> equippedItems;
  Transformation? activeForm;
  FusionForm? activeFusion;
  int fusionTurnsRemaining;
  List<String> unlockedFormIds;
  List<String> unlockedFusionIds;

  PlayerCharacter({
    required this.name,
    this.baseBp = 10,
    this.currentHp = 100,
    this.maxHp = 100,
    this.currentKi = 50,
    this.maxKi = 50,
    this.zeni = 0,
    this.zenkaiBoostCount = 0,
    this.zenkaiMultiplierBonus = 1.0,
    this.permanentKiCostDiscount = 0.0,
    this.wishesGrantedCount = 0,
    this.fusionTurnsRemaining = 0,
    this.activeFusion,
    List<int>? dragonBalls,
    List<Technique>? knownTechniques,
    Map<ItemType, Equipment?>? equippedItems,
    this.activeForm,
    List<String>? unlockedFormIds,
    List<String>? unlockedFusionIds,
  })  : dragonBalls = dragonBalls ?? [],
        knownTechniques = knownTechniques ?? [],
        unlockedFormIds = unlockedFormIds ?? [],
        unlockedFusionIds = unlockedFusionIds ?? [],
        equippedItems = equippedItems ??
            {
              ItemType.gi: null,
              ItemType.weights: null,
              ItemType.scouter: null,
              ItemType.talisman: null,
              ItemType.potara: null,
            };

  bool get hasAllDragonBalls =>
      [1, 2, 3, 4, 5, 6, 7].every((ball) => dragonBalls.contains(ball));

  int get effectiveBp {
    double mult = activeForm?.multiplier ?? 1.0;
    double fusionMult = activeFusion?.bpMultiplier ?? 1.0;
    double itemBonus = 1.0;

    equippedItems.forEach((_, item) {
      if (item != null) {
        itemBonus += item.bpMultiplierBonus;
      }
    });

    return (baseBp * mult * fusionMult * itemBonus).round();
  }

  int getActualKiCost(Technique tech) {
    final cost = (tech.kiCost * (1.0 - permanentKiCostDiscount)).round();
    return cost < 1 ? 1 : cost;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'baseBp': baseBp,
        'currentHp': currentHp,
        'maxHp': maxHp,
        'currentKi': currentKi,
        'maxKi': maxKi,
        'zeni': zeni,
        'zenkaiBoostCount': zenkaiBoostCount,
        'zenkaiMultiplierBonus': zenkaiMultiplierBonus,
        'permanentKiCostDiscount': permanentKiCostDiscount,
        'wishesGrantedCount': wishesGrantedCount,
        'fusionTurnsRemaining': fusionTurnsRemaining,
        'activeFusion': activeFusion?.toJson(),
        'dragonBalls': dragonBalls,
        'knownTechniques': knownTechniques.map((t) => t.toJson()).toList(),
        'equippedItems': equippedItems.map(
          (key, value) => MapEntry(key.index.toString(), value?.toJson()),
        ),
        'activeForm': activeForm?.toJson(),
        'unlockedFormIds': unlockedFormIds,
        'unlockedFusionIds': unlockedFusionIds,
      };

  factory PlayerCharacter.fromJson(Map<String, dynamic> json) {
    var rawEquip = json['equippedItems'] as Map<String, dynamic>? ?? {};
    Map<ItemType, Equipment?> parsedEquip = {};

    for (var type in ItemType.values) {
      var itemJson = rawEquip[type.index.toString()];
      parsedEquip[type] = itemJson != null
          ? Equipment.fromJson(itemJson as Map<String, dynamic>)
          : null;
    }

    return PlayerCharacter(
      name: json['name'] as String,
      baseBp: json['baseBp'] as int,
      currentHp: json['currentHp'] as int,
      maxHp: json['maxHp'] as int,
      currentKi: json['currentKi'] as int,
      maxKi: json['maxKi'] as int,
      zeni: json['zeni'] as int,
      zenkaiBoostCount: json['zenkaiBoostCount'] as int,
      zenkaiMultiplierBonus: (json['zenkaiMultiplierBonus'] as num?)?.toDouble() ?? 1.0,
      permanentKiCostDiscount: (json['permanentKiCostDiscount'] as num?)?.toDouble() ?? 0.0,
      wishesGrantedCount: json['wishesGrantedCount'] as int? ?? 0,
      fusionTurnsRemaining: json['fusionTurnsRemaining'] as int? ?? 0,
      activeFusion: json['activeFusion'] != null
          ? FusionForm.fromJson(json['activeFusion'] as Map<String, dynamic>)
          : null,
      dragonBalls: (json['dragonBalls'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      knownTechniques: (json['knownTechniques'] as List<dynamic>?)
              ?.map((t) => Technique.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      equippedItems: parsedEquip,
      activeForm: json['activeForm'] != null
          ? Transformation.fromJson(json['activeForm'] as Map<String, dynamic>)
          : null,
      unlockedFormIds: (json['unlockedFormIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      unlockedFusionIds: (json['unlockedFusionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  String encodeState() => jsonEncode(toJson());

  static PlayerCharacter decodeState(String jsonString) =>
      PlayerCharacter.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
