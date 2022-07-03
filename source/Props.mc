// Defines app properties (i.e. global state)

// When set specifies what should the background process do next. It should be
// mapped to `WORK_LOGIN` or `WORK_READ_BGS`.
const STORAGE_WORK = "WORK";

// Holds the bg levels.
const STORAGE_BGS = "BGS";

// Holds the current session id.
const STORAGE_SESSION_ID = "SESSION_ID";

// Holds the error message to show on the screen.
const STORAGE_ERROR_MSG = "ERROR_MSG";

// Holds the time (in seconds) of the last API response
const STORAGE_LAST_RESPONSE_TIME_SECS = "LAST_RESPONSE_TIME_SECS";

// Holds the next time (in seconds) a temporal event will be triggered
const STORAGE_NEXT_EVENT_TIME_SECS = "NEXT_EVENT_TIME_SECS";

// `PROP_WORK` value indicating we should get a new session id next.
const WORK_LOGIN = "LOGIN";

// `PROP_WORK` value indicating we should read bgs next.
const WORK_READ_BGS = "READ_BGS";
