import 'dart:async';
import 'package:flutter/material.dart';
import 'models.dart';
import 'game_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DragonBallIncrementalApp());
}

class DragonBallIncrementalApp extends StatelessWidget {
  const DragonBallIncrementalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DB Idle Z',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F141C),
        primaryColor: const Color(0xFFFF8800),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF8800),
          secondary: Color(0xFF00B0FF),
          surface: Color(0xFF1B2230),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1B2230),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  PlayerCharacter? _player;
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  bool _isDragonSummoned = false;

  Timer? _idleLoopTimer;
  Timer? _autoSaveTimer;

  Enemy? _currentEnemy;
  BattleEngine? _battleEngine;
  final List<TurnCombatLog> _combatLogs = [];

  final List<Transformation> _allTransformations = [
    Transformation(
      id: 'kaioken',
      name: 'Kaio-ken x3',
      multiplier: 1.8,
      requiredBp: 8000,
      kiDrainPerTurn: 4,
    ),
    Transformation(
      id: 'ssj1',
      name: 'Super Saiyan (SSJ)',
      multiplier: 3.5,
      requiredBp: 150000,
      kiDrainPerTurn: 8,
    ),
    Transformation(
      id: 'ssj2',
      name: 'Super Saiyan 2 (SSJ2)',
      multiplier: 7.0,
      requiredBp: 1200000,
      kiDrainPerTurn: 16,
    ),
    Transformation(
      id: 'ssj3',
      name: 'Super Saiyan 3 (SSJ3)',
      multiplier: 14.0,
      requiredBp: 8000000,
      kiDrainPerTurn: 32,
    ),
  ];

  final List<FusionForm> _allFusions = [
    FusionForm(
      id: 'gotenks_dance',
      name: 'Gotenks (Taniec Fuzji)',
      type: FusionType.dance,
      bpMultiplier: 5.0,
      durationTurns: 30,
      requiredBp: 1500000,
      zeniCost: 15000,
      description: 'Precyzyjny Taniec Metamoran. Podnosi moc x5 na 30 tur walki.',
    ),
    FusionForm(
      id: 'vegito_potara',
      name: 'Vegito (Kolczyki Potara)',
      type: FusionType.potara,
      bpMultiplier: 18.0,
      durationTurns: 0,
      requiredBp: 12000000,
      zeniCost: 250000,
      description: 'Boska wieczna fuzja potężnych rywali za pomocą Kolczyków Potara.',
    ),
  ];

  final List<Technique> _techniqueCatalog = [
    Technique(
      id: 'masenko',
      name: 'Masenko',
      kiCost: 28,
      damageMultiplier: 2.8,
      type: AttackType.ki,
      requiredBp: 3000,
      zeniCost: 800,
      description: 'Szybki promień Ki skupiony nad czołem.',
    ),
    Technique(
      id: 'instant_transmission',
      name: 'Instant Transmission',
      kiCost: 45,
      damageMultiplier: 2.0,
      type: AttackType.utility,
      effect: TechniqueEffect.evasion,
      requiredBp: 50000,
      zeniCost: 5000,
      description: 'Natychmiastowa teleportacja omijająca kontratak wroga w danej turze.',
    ),
    Technique(
      id: 'final_flash',
      name: 'Final Flash',
      kiCost: 65,
      damageMultiplier: 4.8,
      type: AttackType.ki,
      requiredBp: 200000,
      zeniCost: 25000,
      description: 'Niszczycielski promień dumy Saiyan.',
    ),
    Technique(
      id: 'spirit_bomb',
      name: 'Genki Dama (Spirit Bomb)',
      kiCost: 100,
      damageMultiplier: 8.5,
      type: AttackType.ki,
      effect: TechniqueEffect.chargeUp,
      requiredBp: 600000,
      zeniCost: 100000,
      description: 'Kula czystej energii czerpana ze świata.',
    ),
    Technique(
      id: 'super_ghost_kamikaze',
      name: 'Super Ghost Kamikaze Attack',
      kiCost: 140,
      damageMultiplier: 12.0,
      type: AttackType.ki,
      requiredBp: 2500000,
      zeniCost: 180000,
      description: 'Eksplodujące klony Ki stworzone przez Gotenksa.',
    ),
  ];

  final List<LocationZone> _zones = [
    LocationZone(
      id: 'earth_wasteland',
      name: 'Pustkowia Ziemi (Saga Saiyan)',
      requiredBp: 10,
      possibleEnemies: [
        Enemy(
          name: 'Saibaiman',
          maxHp: 80,
          currentHp: 80,
          battlePower: 15,
          expReward: 5,
          zeniReward: 20,
        ),
        Enemy(
          name: 'Nappa',
          maxHp: 320,
          currentHp: 320,
          battlePower: 80,
          expReward: 25,
          zeniReward: 90,
          dropsDragonBallNumber: 1,
        ),
      ],
      boss: Enemy(
        name: 'Vegeta',
        maxHp: 800,
        currentHp: 800,
        battlePower: 280,
        expReward: 120,
        zeniReward: 400,
        dropsDragonBallNumber: 4,
        specialMove: Technique(
          id: 'vegeta_galick_gun',
          name: 'Galick Gun',
          kiCost: 20,
          damageMultiplier: 2.2,
          type: AttackType.ki,
        ),
      ),
    ),
    LocationZone(
      id: 'planet_namek',
      name: 'Planeta Namek (Saga Ginyu)',
      requiredBp: 1500,
      possibleEnemies: [
        Enemy(
          name: 'Żołnierz Freezera',
          maxHp: 1200,
          currentHp: 1200,
          battlePower: 1100,
          expReward: 180,
          zeniReward: 500,
        ),
        Enemy(
          name: 'Recoome',
          maxHp: 3200,
          currentHp: 3200,
          battlePower: 2600,
          expReward: 420,
          zeniReward: 1200,
          dropsDragonBallNumber: 2,
        ),
      ],
      boss: Enemy(
        name: 'Kapitan Ginyu',
        maxHp: 7500,
        currentHp: 7500,
        battlePower: 6500,
        expReward: 1200,
        zeniReward: 3500,
        dropsDragonBallNumber: 5,
        specialMove: Technique(
          id: 'ginyu_milky_cannon',
          name: 'Milky Cannon',
          kiCost: 25,
          damageMultiplier: 2.4,
          type: AttackType.ki,
        ),
      ),
    ),
    LocationZone(
      id: 'namek_destroyed',
      name: 'Zniszczony Namek (Saga Freezera)',
      requiredBp: 45000,
      possibleEnemies: [
        Enemy(
          name: 'Freezer (Forma 2)',
          maxHp: 18000,
          currentHp: 18000,
          battlePower: 40000,
          expReward: 3200,
          zeniReward: 8000,
        ),
        Enemy(
          name: 'Freezer (Forma 3)',
          maxHp: 35000,
          currentHp: 35000,
          battlePower: 75000,
          expReward: 6500,
          zeniReward: 16000,
          dropsDragonBallNumber: 3,
        ),
      ],
      boss: Enemy(
        name: 'Freezer (100% Mocy)',
        maxHp: 95000,
        currentHp: 95000,
        battlePower: 180000,
        expReward: 25000,
        zeniReward: 60000,
        dropsDragonBallNumber: 6,
        specialMove: Technique(
          id: 'frieza_death_ball',
          name: 'Death Ball',
          kiCost: 40,
          damageMultiplier: 3.2,
          type: AttackType.ki,
        ),
      ),
    ),
    LocationZone(
      id: 'cell_games',
      name: 'Igrzyska Cella (Saga Androidów)',
      requiredBp: 350000,
      possibleEnemies: [
        Enemy(
          name: 'Android 17',
          maxHp: 120000,
          currentHp: 120000,
          battlePower: 280000,
          expReward: 35000,
          zeniReward: 85000,
        ),
        Enemy(
          name: 'Cell Junior',
          maxHp: 200000,
          currentHp: 200000,
          battlePower: 420000,
          expReward: 55000,
          zeniReward: 140000,
        ),
      ],
      boss: Enemy(
        name: 'Perfekcyjny Cell',
        maxHp: 650000,
        currentHp: 650000,
        battlePower: 1200000,
        expReward: 200000,
        zeniReward: 500000,
        dropsDragonBallNumber: 7,
        specialMove: Technique(
          id: 'perfect_kamehameha',
          name: 'Solar Kamehameha',
          kiCost: 60,
          damageMultiplier: 4.0,
          type: AttackType.ki,
        ),
      ),
    ),
    LocationZone(
      id: 'sacred_world_kai',
      name: 'Święty Świat Kai (Saga Majin Buu)',
      requiredBp: 2000000,
      possibleEnemies: [
        Enemy(
          name: 'Dabura (Król Demonów)',
          maxHp: 1200000,
          currentHp: 1200000,
          battlePower: 1800000,
          expReward: 350000,
          zeniReward: 800000,
        ),
        Enemy(
          name: 'Majin Buu (Gruby)',
          maxHp: 2800000,
          currentHp: 2800000,
          battlePower: 4500000,
          expReward: 850000,
          zeniReward: 2000000,
        ),
        Enemy(
          name: 'Super Buu (Gohan Absorb)',
          maxHp: 5500000,
          currentHp: 5500000,
          battlePower: 9200000,
          expReward: 2000000,
          zeniReward: 4500000,
        ),
      ],
      boss: Enemy(
        name: 'Kid Buu (Czyste Zło)',
        maxHp: 14000000,
        currentHp: 14000000,
        battlePower: 22000000,
        expReward: 6000000,
        zeniReward: 15000000,
        dropsDragonBallNumber: 7,
        specialMove: Technique(
          id: 'planet_burst',
          name: 'Planet Burst',
          kiCost: 70,
          damageMultiplier: 4.8,
          type: AttackType.ki,
        ),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initGameState();
  }

  Future<void> _initGameState() async {
    final player = await GameStorage.loadOrCreatePlayer('Son Goku');
    setState(() {
      _player = player;
      _isLoading = false;
    });

    _idleLoopTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_player != null && mounted) {
        setState(() {
          IncrementalTrainingEngine.processIdleTick(_player!, 1);
          _evaluateTransformationsUnlock();

          if (_player!.activeForm != null && _currentEnemy == null) {
            final drain = (_player!.activeForm!.kiDrainPerTurn / 2).ceil();
            if (_player!.currentKi > drain) {
              _player!.currentKi -= drain;
            } else {
              _player!.currentKi = 0;
              _player!.activeForm = null;
            }
          }
        });
      }
    });

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_player != null) {
        GameStorage.savePlayer(_player!);
      }
    });
  }

  void _evaluateTransformationsUnlock() {
    for (var form in _allTransformations) {
      if (!_player!.unlockedFormIds.contains(form.id) &&
          _player!.baseBp >= form.requiredBp) {
        _player!.unlockedFormIds.add(form.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFFF8800),
            content: Text(
              'Osiągnięto nowy poziom mocy! Odblokowano: ${form.name}!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _idleLoopTimer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _triggerPushUps() {
    if (_player == null) return;
    setState(() {
      IncrementalTrainingEngine.executePushUps(_player!);
      _evaluateTransformationsUnlock();
    });
  }

  void _triggerMeditation() {
    if (_player == null) return;
    setState(() {
      IncrementalTrainingEngine.executeMeditation(_player!);
    });
  }

  void _toggleTransformation(Transformation form) {
    setState(() {
      if (_player!.activeForm?.id == form.id) {
        _player!.activeForm = null;
      } else {
        if (_player!.currentKi >= form.kiDrainPerTurn * 2) {
          _player!.activeForm = form;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Zbyt mało Ki na utrzymanie formy!')),
          );
        }
      }
    });
    GameStorage.savePlayer(_player!);
  }

  void _learnFusion(FusionForm fusion) {
    if (_player == null) return;
    if (_player!.unlockedFusionIds.contains(fusion.id)) return;

    if (_player!.effectiveBp < fusion.requiredBp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zbyt niska moc bojowa (BP) do opanowania tej fuzji!')),
      );
      return;
    }

    if (_player!.zeni < fusion.zeniCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Niewystarczająca liczba Zeni!')),
      );
      return;
    }

    setState(() {
      _player!.zeni -= fusion.zeniCost;
      _player!.unlockedFusionIds.add(fusion.id);
    });
    GameStorage.savePlayer(_player!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.purpleAccent,
        content: Text('Opanowano rytuał fuzji: ${fusion.name}!'),
      ),
    );
  }

  void _toggleFusion(FusionForm fusion) {
    setState(() {
      if (_player!.activeFusion?.id == fusion.id) {
        _player!.activeFusion = null;
        _player!.fusionTurnsRemaining = 0;
      } else {
        _player!.activeFusion = fusion;
        _player!.fusionTurnsRemaining = fusion.durationTurns;
      }
    });
    GameStorage.savePlayer(_player!);
  }

  void _learnTechnique(Technique tech) {
    if (_player == null) return;
    if (_player!.knownTechniques.any((t) => t.id == tech.id)) return;

    if (_player!.effectiveBp < tech.requiredBp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Twoja moc bojowa (BP) jest zbyt mała!')),
      );
      return;
    }

    if (_player!.zeni < tech.zeniCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak wystarczającej liczby Zeni!')),
      );
      return;
    }

    setState(() {
      _player!.zeni -= tech.zeniCost;
      _player!.knownTechniques.add(tech);
    });

    GameStorage.savePlayer(_player!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text('Pomyślnie opanowano: ${tech.name}!'),
      ),
    );
  }

  void _fulfillWish(int wishIndex) {
    if (_player == null || !_player!.hasAllDragonBalls) return;

    setState(() {
      _player!.dragonBalls.clear();
      _player!.wishesGrantedCount += 1;
      _isDragonSummoned = false;

      switch (wishIndex) {
        case 0:
          _player!.baseBp = (_player!.baseBp * 1.5).round();
          break;
        case 1:
          _player!.zeni += 500000;
          break;
        case 2:
          _player!.zenkaiMultiplierBonus += 0.5;
          break;
        case 3:
          if (_player!.permanentKiCostDiscount < 0.6) {
            _player!.permanentKiCostDiscount += 0.2;
          }
          break;
      }
    });

    GameStorage.savePlayer(_player!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.amber,
        content: Text(
          'Shenron spełnił Twoje życzenie! Kule rozproszyły się po wszechświecie.',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _startEncounter(Enemy enemyTemplate) {
    setState(() {
      _currentEnemy = Enemy(
        name: enemyTemplate.name,
        maxHp: enemyTemplate.maxHp,
        currentHp: enemyTemplate.maxHp,
        battlePower: enemyTemplate.battlePower,
        expReward: enemyTemplate.expReward,
        zeniReward: enemyTemplate.zeniReward,
        specialMove: enemyTemplate.specialMove,
        dropsDragonBallNumber: enemyTemplate.dropsDragonBallNumber,
      );
      _battleEngine = BattleEngine(player: _player!, enemy: _currentEnemy!);
      _combatLogs.clear();
      _combatLogs.add(TurnCombatLog(
        actorName: 'System',
        actionDescription: 'Przeciwnik ${_currentEnemy!.name} staje do walki!',
        damageDealt: 0,
        isPlayerAction: true,
      ));
      _selectedTabIndex = 1;
    });
  }

  void _handleCombatAction(bool isPhysical, [Technique? tech]) {
    if (_battleEngine == null || _currentEnemy == null || _player == null) return;

    final result = isPhysical
        ? _battleEngine!.executePlayerPhysicalAttack()
        : _battleEngine!.executePlayerTechnique(tech!);

    setState(() {
      _combatLogs.insertAll(0, result.logs.reversed);
      _evaluateTransformationsUnlock();

      if (result.isFinished) {
        if (result.playerWon) {
          String extraMsg = '';
          if (result.awardedDragonBall != null) {
            extraMsg = ' Odnaleziono Smoczą Kulę (${result.awardedDragonBall}★)!';
          }
          _combatLogs.insert(
            0,
            TurnCombatLog(
              actorName: 'System',
              actionDescription:
                  'Zwycięstwo! Otrzymujesz ${result.expGained} BP oraz ${result.zeniGained} Zeni.$extraMsg',
              damageDealt: 0,
              isPlayerAction: true,
            ),
          );
        } else {
          _combatLogs.insert(
            0,
            TurnCombatLog(
              actorName: 'System',
              actionDescription: result.triggeredZenkai
                  ? 'Porażka! Saiyańska krew wzmacnia ciało - Zenkai Boost aktywowane!'
                  : 'Zostałeś pokonany!',
              damageDealt: 0,
              isPlayerAction: false,
            ),
          );
        }
        _currentEnemy = null;
        _battleEngine = null;
      }
    });

    GameStorage.savePlayer(_player!);
  }

  void _buyEquipment(Equipment item, int price) {
    if (_player == null) return;
    if (_player!.zeni < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak wystarczającej liczby Zeni!')),
      );
      return;
    }

    setState(() {
      _player!.zeni -= price;
      _player!.equippedItems[item.type] = item;
    });
    GameStorage.savePlayer(_player!);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _player == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF8800)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF141A24),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _player!.activeFusion?.name ?? _player!.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'Zenkai: x${_player!.zenkaiBoostCount} | Zeni: ${_player!.zeni} | Kule: ${_player!.dragonBalls.length}/7',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade300),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Zapisz grę',
            onPressed: () async {
              await GameStorage.savePlayer(_player!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stan gry zapisany!')),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildVitalsCard(),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _buildTrainingTab(),
                  _buildCombatTab(),
                  _buildTechniquesTab(),
                  _buildShenronTab(),
                  _buildEquipmentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF141A24),
        currentIndex: _selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF8800),
        unselectedItemColor: Colors.grey.shade500,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Trening',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on),
            label: 'Walka',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_fix_high),
            label: 'Techniki',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stars),
            label: 'Shenron',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield),
            label: 'Rynsztunek',
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard() {
    final hpPercent = (_player!.maxHp > 0)
        ? (_player!.currentHp / _player!.maxHp).clamp(0.0, 1.0)
        : 0.0;
    final kiPercent = (_player!.maxKi > 0)
        ? (_player!.currentKi / _player!.maxKi).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF141A24),
        border: Border(bottom: BorderSide(color: Color(0xFF283347), width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BP: ${_player!.effectiveBp}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF8800),
                ),
              ),
              Row(
                children: [
                  if (_player!.activeFusion != null)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.purpleAccent),
                      ),
                      child: Text(
                        _player!.activeFusion!.durationTurns > 0
                            ? '${_player!.activeFusion!.name} (${_player!.fusionTurnsRemaining}T)'
                            : _player!.activeFusion!.name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                  if (_player!.activeForm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amberAccent),
                      ),
                      child: Text(
                        _player!.activeForm!.name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBar('HP', '${_player!.currentHp}/${_player!.maxHp}', hpPercent, Colors.redAccent),
          const SizedBox(height: 6),
          _buildBar('KI', '${_player!.currentKi}/${_player!.maxKi}', kiPercent, const Color(0xFF00B0FF)),
        ],
      ),
    );
  }

  Widget _buildBar(String label, String valText, double percent, Color barColor) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 14,
                  backgroundColor: Colors.black38,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              Text(
                valText,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'TRANSFORMACJE SAIYAN (DO SSJ3)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  const SizedBox(height: 8),
                  if (_allTransformations.where((f) => _player!.unlockedFormIds.contains(f.id)).isEmpty)
                    const Text(
                      'Wymagane BP (min. 8,000 dla Kaio-ken), by zmienić formę.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allTransformations
                          .where((f) => _player!.unlockedFormIds.contains(f.id))
                          .map((form) {
                        final isActive = _player!.activeForm?.id == form.id;
                        return ChoiceChip(
                          selectedColor: const Color(0xFFFF8800),
                          label: Text(
                            '${form.name} (x${form.multiplier} BP)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : Colors.amberAccent,
                            ),
                          ),
                          selected: isActive,
                          onSelected: (_) => _toggleTransformation(form),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'RYTUŁY FUZJI (GOTENKS / VEGITO)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                  ),
                  const SizedBox(height: 8),
                  ..._allFusions.map((fusion) {
                    final isUnlocked = _player!.unlockedFusionIds.contains(fusion.id);
                    final isActive = _player!.activeFusion?.id == fusion.id;
                    final hasBp = _player!.effectiveBp >= fusion.requiredBp;
                    final hasZeni = _player!.zeni >= fusion.zeniCost;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fusion.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  '${fusion.description}\nMnożnik: x${fusion.bpMultiplier} BP',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          if (isUnlocked)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive ? Colors.purple : Colors.grey.shade700,
                              ),
                              onPressed: () => _toggleFusion(fusion),
                              child: Text(isActive ? 'Rozłącz' : 'Połącz'),
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8800),
                              ),
                              onPressed: (hasBp && hasZeni) ? () => _learnFusion(fusion) : null,
                              child: Text('${fusion.zeniCost} Z'),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'SALA DUCHA I CZASU',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Zintensyfikowany trening budujący potęgę pod walkę z Kid Buu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8800),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _triggerPushUps,
                    icon: const Icon(Icons.fitness_center),
                    label: const Text('TRENING DUCHA (+BP)'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B0FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _triggerMeditation,
                    icon: const Icon(Icons.self_improvement),
                    label: const Text('MEDYTACJA KI (+KI)'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombatTab() {
    if (_currentEnemy != null) {
      return _buildActiveBattleView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _zones.length,
      itemBuilder: (context, index) {
        final zone = _zones[index];
        final canEnter = _player!.effectiveBp >= zone.requiredBp;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        zone.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      'Wymagane: ${zone.requiredBp} BP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: canEnter ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (!canEnter)
                  const Text(
                    'Zbyt niska moc bojowa. Trenuj dalej lub użyj Fuzji!',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  )
                else ...[
                  const Text('Przeciwnicy w lokacji:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: zone.possibleEnemies.map((e) {
                      return OutlinedButton(
                        onPressed: () => _startEncounter(e),
                        child: Text('${e.name} (${e.battlePower} BP)'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Boss sagi:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _startEncounter(zone.boss),
                    child: Text('STARCIE: ${zone.boss.name} (${zone.boss.battlePower} BP)'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveBattleView() {
    final enemyHpPercent = (_currentEnemy!.maxHp > 0)
        ? (_currentEnemy!.currentHp / _currentEnemy!.maxHp).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Card(
            color: const Color(0xFF221115),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currentEnemy!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                      Text('BP: ${_currentEnemy!.battlePower}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBar('HP', '${_currentEnemy!.currentHp}/${_currentEnemy!.maxHp}', enemyHpPercent, Colors.red),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                  onPressed: () => _handleCombatAction(true),
                  child: const Text('Atak Wręcz (+Ki)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_player!.knownTechniques.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _player!.knownTechniques.map((t) {
                  final cost = _player!.getActualKiCost(t);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF00558F),
                      label: Text('${t.name} ($cost Ki)'),
                      onPressed: () => _handleCombatAction(false, t),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _combatLogs.length,
                itemBuilder: (context, idx) {
                  final log = _combatLogs[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${log.actorName}: ${log.actionDescription} ${log.damageDealt > 0 ? "[-${log.damageDealt}]" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        color: log.isPlayerAction ? Colors.lightBlueAccent : Colors.red.shade300,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniquesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'OPANOWANE TECHNIKI KI',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
        ),
        const SizedBox(height: 8),
        ..._player!.knownTechniques.map((t) {
          final cost = _player!.getActualKiCost(t);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Koszt Ki: $cost | Mnożnik: x${t.damageMultiplier}\n${t.description}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.check_circle, color: Colors.greenAccent),
            ),
          );
        }),
        const SizedBox(height: 20),
        const Text(
          'DRZEWKO TECHNIK MISTRZÓW (DOJO)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        const SizedBox(height: 8),
        ..._techniqueCatalog.map((tech) {
          final isKnown = _player!.knownTechniques.any((t) => t.id == tech.id);
          final hasEnoughBp = _player!.effectiveBp >= tech.requiredBp;
          final hasEnoughZeni = _player!.zeni >= tech.zeniCost;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tech.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Koszt: ${tech.zeniCost} Zeni',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasEnoughZeni ? Colors.amberAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tech.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Wymaga: ${tech.requiredBp} BP',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasEnoughBp ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isKnown ? Colors.grey : const Color(0xFFFF8800),
                        ),
                        onPressed: isKnown ? null : () => _learnTechnique(tech),
                        child: Text(isKnown ? 'Nauczono' : 'Trenuj technikę'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShenronTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFF132219),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'OŁTARZ BOSKIEGO SMOKA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.greenAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zbierz 7 Smoczych Kul z bossów sag, aby wezwać Shenrona.\nSpełnione życzenia: ${_player!.wishesGrantedCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(7, (idx) {
                      final starNum = idx + 1;
                      final hasBall = _player!.dragonBalls.contains(starNum);
                      return Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasBall ? const Color(0xFFFF9900) : Colors.black45,
                          border: Border.all(
                            color: hasBall ? Colors.amberAccent : Colors.grey.shade700,
                            width: 2,
                          ),
                          boxShadow: hasBall
                              ? [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$starNum★',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: hasBall ? Colors.red.shade900 : Colors.grey.shade600,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _player!.hasAllDragonBalls ? Colors.green.shade700 : Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: _player!.hasAllDragonBalls
                        ? () => setState(() => _isDragonSummoned = true)
                        : null,
                    icon: const Icon(Icons.flash_on),
                    label: const Text('PRZYZOŁAJ SHENRONA'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isDragonSummoned) ...[
            const Text(
              'WYBIERZ JEDNO ŻYCZENIE:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
            const SizedBox(height: 8),
            _buildWishCard(
              title: 'Obudź mój ukryty potencjał!',
              desc: 'Trwale zwiększa Twoje bazowe BP o +50%.',
              onTap: () => _fulfillWish(0),
            ),
            _buildWishCard(
              title: 'Pragnę nieprzeliczonych bogactw!',
              desc: 'Otrzymujesz natychmiast 500,000 Zeni.',
              onTap: () => _fulfillWish(1),
            ),
            _buildWishCard(
              title: 'Wzmocnij saiyański instynkt Zenkai!',
              desc: 'Trwale zwiększa bonus z każdego zgonu o kolejne +50%.',
              onTap: () => _fulfillWish(2),
            ),
            _buildWishCard(
              title: 'Pozwól mi lepiej kontrolować energię Ki!',
              desc: 'Trwały rabat -20% do kosztu Ki dla wszystkich technik.',
              onTap: () => _fulfillWish(3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWishCard({required String title, required String desc, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8800)),
          onPressed: onTap,
          child: const Text('Żądaj!'),
        ),
      ),
    );
  }

  Widget _buildEquipmentTab() {
    final catalog = [
      Equipment(
        id: 'gravity_suit',
        name: 'Kombinezon Grawitacyjny 300G',
        type: ItemType.weights,
        trainingMultiplier: 4.0,
      ),
      Equipment(
        id: 'scouter_red',
        name: 'Czerwony Scouter Armii Freezera',
        type: ItemType.scouter,
        bpMultiplierBonus: 0.35,
      ),
      Equipment(
        id: 'potara_earrings',
        name: 'Kolczyki Potara Świętych Kai',
        type: ItemType.potara,
        bpMultiplierBonus: 1.2,
        trainingMultiplier: 2.0,
      ),
      Equipment(
        id: 'yardrat_gi',
        name: 'Szaty z Planety Yardrat',
        type: ItemType.gi,
        bpMultiplierBonus: 0.5,
        trainingMultiplier: 1.8,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'EKWIPUNEK W UŻYCIU',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        const SizedBox(height: 8),
        ...ItemType.values.map((type) {
          final item = _player!.equippedItems[type];
          return ListTile(
            dense: true,
            tileColor: const Color(0xFF1B2230),
            title: Text('${type.name.toUpperCase()}: ${item?.name ?? "(Brak)"}'),
            subtitle: item != null
                ? Text('Bonus BP: +${(item.bpMultiplierBonus * 100).toInt()}% | Mnożnik: x${item.trainingMultiplier}')
                : null,
          );
        }),
        const SizedBox(height: 20),
        const Text(
          'RYNSZTUNEK CAPSULE CORP & ZAŚWIATÓW',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        const SizedBox(height: 8),
        ...catalog.map((item) {
          final cost = item.type == ItemType.potara ? 100000 : 15000;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item.name),
              subtitle: Text('Trening: x${item.trainingMultiplier} | Bonus BP: +${(item.bpMultiplierBonus * 100).toInt()}%'),
              trailing: ElevatedButton(
                onPressed: () => _buyEquipment(item, cost),
                child: Text('$cost Z'),
              ),
            ),
          );
        }),
      ],
    );
  }
}
