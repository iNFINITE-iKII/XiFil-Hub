# Graph Report - artifacts/api-server/lua  (2026-07-15)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 415 nodes · 739 edges · 34 communities (32 shown, 2 thin omitted)
- Extraction: 87% EXTRACTED · 13% INFERRED · 0% AMBIGUOUS · INFERRED: 94 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `06bd7724`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- combat.lua
- startFarmLoop
- ui_core.lua
- ui_core.lua
- xifil_hub_full.lua
- startFarmLoop
- GetThemeColor
- SyncAllVisualUI
- SyncAllVisualUI
- config_system.lua
- ironsoulbeta.lua
- loader.lua
- ironsoulv1.lua
- loader.lua
- soul_iron.lua
- loader.lua
- _template.lua
- promptKey
- tab_sell.lua
- CustomNotify
- init.lua
- init.lua
- tab_autobuy.lua
- updateModeDropdown

## God Nodes (most connected - your core abstractions)
1. `startFarmLoop()` - 16 edges
2. `startFarmLoop()` - 14 edges
3. `startFarmLoop()` - 14 edges
4. `GetThemeColor()` - 14 edges
5. `GetThemeColor()` - 14 edges
6. `GetThemeColor()` - 13 edges
7. `ApplyAllVisuals()` - 10 edges
8. `ApplyAllVisuals()` - 10 edges
9. `ApplyAllVisuals()` - 10 edges
10. `RegisterThemeElement()` - 9 edges

## Surprising Connections (you probably didn't know these)
- `makeCatBtn()` --calls--> `RegisterTranslation()`  [INFERRED]
  games/ironsoulv1/ui/tab_autobuy.lua → games/ironsoulv1/translate.lua
- `startFarmLoop()` --calls--> `GetPositionCFrame()`  [INFERRED]
  games/ironsoulbeta/farm.lua → games/ironsoulbeta/combat.lua
- `startFarmLoop()` --calls--> `ApplyMovement()`  [INFERRED]
  games/ironsoulbeta/farm.lua → games/ironsoulbeta/combat.lua
- `FireReplayRemote()` --calls--> `CustomNotify()`  [INFERRED]
  games/ironsoulbeta/combat.lua → games/ironsoulbeta/notify.lua
- `PlayIntroAnimation()` --calls--> `GetThemeColor()`  [INFERRED]
  games/ironsoulbeta/init.lua → games/ironsoulbeta/ui/ui_core.lua

## Import Cycles
- None detected.

## Communities (34 total, 2 thin omitted)

### Community 0 - "combat.lua"
Cohesion: 0.08
Nodes (35): ApplyMovement(), checkVictoryUi(), CombatEngine.GetLevelType(), CombatEngine.GetNpcId(), CombatEngine.GetValidChests(), CombatEngine.GetValidMonsters(), CombatEngine.InterruptableStall(), CombatEngine.ResetPhysics() (+27 more)

### Community 1 - "startFarmLoop"
Cohesion: 0.08
Nodes (34): ApplyMovement(), checkVictoryUi(), CombatEngine.GetLevelType(), CombatEngine.GetNpcId(), CombatEngine.GetValidChests(), CombatEngine.GetValidMonsters(), CombatEngine.InterruptableStall(), CombatEngine.ResetPhysics() (+26 more)

### Community 2 - "ui_core.lua"
Cohesion: 0.11
Nodes (26): ApplyTranslations(), RegisterTranslation(), RegisterTranslationFn(), makeCatBtn(), ApplyAllVisuals(), ApplyBgColorTheme(), ApplyBgEffect(), ApplyButtonShape() (+18 more)

### Community 3 - "ui_core.lua"
Cohesion: 0.12
Nodes (25): ApplyTranslations(), RegisterTranslation(), RegisterTranslationFn(), ApplyAllVisuals(), ApplyBgColorTheme(), ApplyBgEffect(), ApplyButtonShape(), ApplyFont() (+17 more)

### Community 4 - "xifil_hub_full.lua"
Cohesion: 0.08
Nodes (15): ApplyAllVisuals(), ApplyBgColorTheme(), ApplyBgEffect(), ApplyButtonShape(), ApplyFont(), ApplyTabMode(), ApplyTheme(), ApplyToggleShape() (+7 more)

### Community 5 - "startFarmLoop"
Cohesion: 0.15
Nodes (22): anyActiveTargetExists(), anyFarmToggleActive(), ApplyMovement(), checkVictoryUi(), CombatEngine.GetLevelType(), CombatEngine.GetNpcId(), CombatEngine.GetValidChests(), CombatEngine.GetValidMonsters() (+14 more)

### Community 6 - "GetThemeColor"
Cohesion: 0.21
Nodes (16): CreateButton(), CreateCycleUI(), CreateDropdownUI(), CreateInputUI(), CreateMultiCheckUI(), CreateSection(), CreateSliderUI(), CreateTab() (+8 more)

### Community 7 - "SyncAllVisualUI"
Cohesion: 0.30
Nodes (8): getModeLabel(), isCaveWorld(), isEndlessTower(), _clampRoomMode(), SyncAllVisualUI(), buildModeList(), getModeNumber(), updateModeDropdown()

### Community 8 - "SyncAllVisualUI"
Cohesion: 0.35
Nodes (8): getModeLabel(), isCaveWorld(), isEndlessTower(), _clampRoomMode(), SyncAllVisualUI(), buildModeList(), getModeNumber(), updateModeDropdown()

### Community 9 - "config_system.lua"
Cohesion: 0.24
Nodes (7): ConfigSystem.ExecuteAutoLoad(), ConfigSystem.GetAutoLoadPointer(), ConfigSystem.GetConfigList(), ConfigSystem.Load(), ConfigSystem.OverwriteExisting(), ConfigSystem.SaveNew(), RefreshConfigDropdown()

### Community 10 - "ironsoulbeta.lua"
Cohesion: 0.42
Nodes (8): checkLicense(), deleteKey(), getHWID(), promptKey(), readKey(), saveKey(), startWithDRM(), tween()

### Community 11 - "loader.lua"
Cohesion: 0.42
Nodes (8): checkLicense(), deleteKey(), getHWID(), promptKey(), readKey(), saveKey(), startWithDRM(), tween()

### Community 12 - "ironsoulv1.lua"
Cohesion: 0.42
Nodes (8): checkLicense(), deleteKey(), getHWID(), promptKey(), readKey(), saveKey(), startWithDRM(), tween()

### Community 13 - "loader.lua"
Cohesion: 0.42
Nodes (8): checkLicense(), deleteKey(), getHWID(), promptKey(), readKey(), saveKey(), startWithDRM(), tween()

### Community 14 - "soul_iron.lua"
Cohesion: 0.42
Nodes (8): checkLicense(), deleteKey(), getHWID(), promptKey(), readKey(), saveKey(), startWithDRM(), tween()

### Community 15 - "loader.lua"
Cohesion: 0.42
Nodes (8): checkLicense(), deleteKey(), getHWID(), promptKey(), readKey(), saveKey(), startWithDRM(), tween()

### Community 16 - "_template.lua"
Cohesion: 0.50
Nodes (8): checkLicense(), deleteKey(), getHWID(), promptKey(), readKey(), saveKey(), startWithDRM(), tween()

### Community 17 - "promptKey"
Cohesion: 0.36
Nodes (8): checkLicense(), deleteKey(), getHWID(), promptKey(), readKey(), saveKey(), startWithDRM(), tween()

### Community 18 - "tab_sell.lua"
Cohesion: 0.43
Nodes (4): _cleanSR(), _detectRarity(), doSellByRarity(), _getOresScrollSR()

### Community 21 - "CustomNotify"
Cohesion: 0.33
Nodes (6): ConfigSystem.ExecuteAutoLoad(), ConfigSystem.GetAutoLoadPointer(), ConfigSystem.Load(), CustomNotify(), DisableAutoFarm(), FireReplayRemote()

### Community 24 - "tab_autobuy.lua"
Cohesion: 0.50
Nodes (3): getVisualName(), makeCatBtn(), scanSF()

### Community 25 - "updateModeDropdown"
Cohesion: 0.40
Nodes (5): buildModeList(), getModeLabel(), getModeNumber(), isCaveWorld(), updateModeDropdown()

## Knowledge Gaps
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CustomNotify()` connect `startFarmLoop` to `config_system.lua`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **Why does `CustomNotify()` connect `combat.lua` to `tab_sell.lua`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Are the 12 inferred relationships involving `startFarmLoop()` (e.g. with `ApplyMovement()` and `checkVictoryUi()`) actually correct?**
  _`startFarmLoop()` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Are the 12 inferred relationships involving `startFarmLoop()` (e.g. with `ApplyMovement()` and `checkVictoryUi()`) actually correct?**
  _`startFarmLoop()` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Should `combat.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.0797872340425532 - nodes in this community are weakly interconnected._
- **Should `startFarmLoop` be split into smaller, more focused modules?**
  _Cohesion score 0.0797872340425532 - nodes in this community are weakly interconnected._
- **Should `ui_core.lua` be split into smaller, more focused modules?**
  _Cohesion score 0.1066066066066066 - nodes in this community are weakly interconnected._