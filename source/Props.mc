// Defines app properties (i.e. global state)

// When set specifies what should the background process do next. It should be
// mapped to `WORK_LOGIN` or `WORK_READ_BGS`.
(:background)
const PROP_WORK = "PROP_WORK";

// Holds the bg levels.
(:background)
const PROP_BGS = "BGS";

// Holds the current session id.
(:background)
const PROP_SESSION_ID = "SESSION_ID";

// Holds the error message to show on the screen.
(:background)
const PROP_ERROR_MSG = "ERROR_MSG";

// `PROP_WORK` value indicating we should get a new session id next.
(:background)
const WORK_LOGIN = "LOGIN";

// `PROP_WORK` value indicating we should read bgs next.
(:background)
const WORK_READ_BGS = "READ_BGS";
