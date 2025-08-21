# Mac Power Tools Migration Execution Plan

## Current Status: Phase 1 Complete ✅

The migration from a hybrid system to a pure plugin architecture is underway. This document tracks the execution plan and progress.

## Architecture Overview

### Unified Script (`mac`)
- **Version**: 3.0.0
- **Architecture**: Unified (Plugin + Legacy)
- **Operation Mode**: plugin-first (configurable)
- **Features**:
  - Seamless integration of plugin and legacy systems
  - Backward compatibility maintained
  - Plugin-first with legacy fallback
  - Configurable operation mode via MAC_OPERATION_MODE environment variable

## Phase 1: Unified Architecture ✅ COMPLETE

### Completed Tasks:
1. ✅ Created unified `mac` script combining both architectures
2. ✅ Implemented dual-mode operation (plugin-first/legacy-first)
3. ✅ Tested all plugin commands work correctly
4. ✅ Tested all legacy commands work correctly
5. ✅ Backed up original mac script as `mac.backup-v2.4.0`
6. ✅ Replaced main `mac` script with unified version

### Key Features Implemented:
- Intelligent command routing (tries plugin first, falls back to legacy)
- Unified help system showing both plugin and legacy commands
- Plugin management commands integrated
- Environment variable support for operation mode
- Protected path resolution (MAC_HOME_DIR) to prevent conflicts

## Phase 2: Native Plugin Implementation (IN PROGRESS)

### Execution Strategy:

#### 2.1 Plugin Conversion Priority
Plugins will be converted based on complexity and dependencies:

**Simple Plugins** (Convert First):
- `help` - Pure display logic
- `version` - Simple system info
- `awake` - Single script dependency
- `shortcuts` - Limited functionality

**Medium Complexity** (Convert Second):
- `info` - Multiple data sources but straightforward
- `memory` - System calls with formatting
- `battery` - Power management APIs
- `duplicates` - File system operations

**Complex Plugins** (Convert Last):
- `update` - Multiple package managers
- `maintenance` - Interactive menus
- `uninstall` - Application detection
- `linuxify` - System configuration

#### 2.2 Conversion Process for Each Plugin

1. **Analyze Legacy Script**
   ```bash
   # Example: Converting battery plugin
   # Current: plugins/available/battery/main.sh calls scripts/mac-battery.sh
   # Target: Native implementation in plugins/available/battery/main.sh
   ```

2. **Extract Core Logic**
   - Identify system commands used
   - Document dependencies
   - Note any external tools required

3. **Implement Native Plugin**
   - Copy core logic to plugin's main.sh
   - Remove wrapper code
   - Add proper error handling
   - Implement plugin API correctly

4. **Test Native Implementation**
   - Unit test each command
   - Integration test with main script
   - Performance comparison with legacy

5. **Update Metadata**
   - Remove `legacy_script` from plugin.json
   - Update version number
   - Mark as native implementation

### Sample Native Plugin Template:

```bash
#!/bin/bash

# Native Plugin Implementation
# No dependency on legacy scripts

# Source the plugin API
source "${MAC_POWER_TOOLS_HOME}/lib/plugin-api.sh"

# Plugin configuration
PLUGIN_NAME="battery"
PLUGIN_VERSION="2.0.0"
PLUGIN_DESCRIPTION="Native battery management implementation"

# Plugin main entry point
plugin_main() {
    local command="${1:-status}"
    shift
    
    case "$command" in
        status)
            show_battery_status "$@"
            ;;
        health)
            show_battery_health "$@"
            ;;
        *)
            print_error "Unknown command: $command"
            return 1
            ;;
    esac
}

# Implementation functions
show_battery_status() {
    # Native implementation here
    pmset -g batt
}

show_battery_health() {
    # Native implementation here
    system_profiler SPPowerDataType
}

# Initialize the plugin
plugin_init

# Call the main function if not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    plugin_main "$@"
fi
```

## Phase 3: Legacy Cleanup (PLANNED)

### Tasks:
1. **Remove Legacy Scripts** (After all plugins converted)
   - Archive scripts directory
   - Remove from version control
   - Update .gitignore

2. **Clean Up Unified Script**
   - Remove legacy command routing
   - Remove legacy fallback logic
   - Simplify to pure plugin architecture

3. **Update Documentation**
   - Update README.md
   - Update CLAUDE.md
   - Create plugin development guide

4. **Final Testing**
   - Full regression test suite
   - Performance benchmarks
   - User acceptance testing

## Testing Strategy

### Phase 1 Tests ✅
- [x] Unified script loads correctly
- [x] Plugin commands execute
- [x] Legacy commands execute
- [x] Plugin management works
- [x] Help system displays correctly

### Phase 2 Tests (Per Plugin)
- [ ] Native implementation matches legacy behavior
- [ ] Performance is equal or better
- [ ] Error handling is robust
- [ ] Help text is accurate
- [ ] No dependency on legacy scripts

### Phase 3 Tests
- [ ] All plugins work without legacy scripts
- [ ] No references to scripts directory
- [ ] Clean uninstall/reinstall works
- [ ] Homebrew formula updates correctly

## Rollback Procedures

### Phase 1 Rollback
```bash
# Restore original mac script
cp mac.backup-v2.4.0 mac
```

### Phase 2 Rollback
```bash
# Revert individual plugin to wrapper
git checkout -- plugins/available/<plugin-name>/main.sh
```

### Phase 3 Rollback
```bash
# Full restoration from git
git checkout v2.4.0 -- scripts/
git checkout v2.4.0 -- mac
```

## Success Metrics

1. **Functionality**: All commands work identically to legacy
2. **Performance**: No degradation in response time
3. **Maintainability**: Easier to add new plugins
4. **Testing**: Comprehensive test coverage
5. **Documentation**: Clear plugin development guide

## Timeline

- **Phase 1**: ✅ Complete (Day 1)
- **Phase 2**: In Progress (Days 2-4)
  - Simple plugins: Day 2
  - Medium plugins: Day 3
  - Complex plugins: Day 4
- **Phase 3**: Planned (Day 5)

## Next Immediate Actions

1. Start converting simple plugins (help, version)
2. Create plugin conversion script/tool
3. Set up automated testing for native plugins
4. Document plugin API thoroughly

## Configuration Options

The unified script supports configuration via:

1. **Environment Variables**:
   ```bash
   export MAC_OPERATION_MODE=legacy-first  # Use legacy commands first
   export MAC_OPERATION_MODE=plugin-first  # Default - use plugins first
   ```

2. **Config File** (Future):
   ```bash
   # ~/.mac-power-tools/config
   operation_mode=plugin-first
   plugin_path=/custom/plugin/path
   ```

## Notes

- The unified architecture provides a smooth transition path
- No functionality is lost during migration
- Users can continue using the tool without disruption
- Rollback is possible at any phase