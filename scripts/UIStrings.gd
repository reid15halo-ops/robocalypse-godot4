extends RefCounted
class_name UIStrings

# Centralized UI strings for localization-friendly formatting

static func hud_hp(current: int, maximum: int) -> String:
    # Uses localized token for "HP"
    return "%s: %d/%d" % [tr("HP"), current, maximum]

static func hud_shield(value: int) -> String:
    # Uses localized token for "Shield"
    return "%s: %d" % [tr("Shield"), value]

