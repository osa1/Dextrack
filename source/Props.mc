// Defines app properties (i.e. global state)

// When set specifies what should the background process do next. It should be
// mapped to `WORK_LOGIN` or `WORK_READ_BGS`.
const PROP_WORK = "PROP_WORK";

// Holds the bg levels.
const PROP_BGS = "BGS";

// Holds the current session id.
const PROP_SESSION_ID = "SESSION_ID";

// Holds the error message to show on the screen.
const PROP_ERROR_MSG = "ERROR_MSG";

// `PROP_WORK` value indicating we should get a new session id next.
const WORK_LOGIN = "LOGIN";

// `PROP_WORK` value indicating we should read bgs next.
const WORK_READ_BGS = "READ_BGS";
