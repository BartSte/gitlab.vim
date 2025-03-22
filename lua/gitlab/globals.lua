local globals = {
    PLUGIN_VERSION = '1.1.0',

    -- Code Suggestions
    GCS_UNKNOWN = -1,
    GCS_UNKNOWN_TEXT = 'unknown',
    GCS_AVAILABLE_AND_ENABLED = 0,
    GCS_AVAILABLE_AND_ENABLED_TEXT = 'enabled',
    GCS_AVAILABLE_BUT_DISABLED = 1,
    GCS_AVAILABLE_BUT_DISABLED_TEXT = 'inactive',
    GCS_CHECKING = 2,
    GCS_CHECKING_TEXT = 'checking',
    GCS_UNAVAILABLE = 3,
    GCS_UNAVAILABLE_TEXT = 'unavailable',
    GCS_INSTALLED = 5,
    GCS_INSTALLED_TEXT = 'installed',
    GCS_UPDATED = 6,
    GCS_UPDATED_TEXT = 'updated',
    GCS_WAITING = 7, -- waiting for response
    GCS_WAITING_TEXT = 'waiting',
    GCS_SUCCESS = 8, -- got a valid response
    GCS_SUCCESS_TEXT = 'success',
    GCS_ERROR = 9,   -- got an invalid or empty response
    GCS_FAILED_TEXT = 'failed',
    GCS_NONE = 10,   -- got an invalid or empty response
    GCS_NONE_TEXT = 'none',
}

return globals
