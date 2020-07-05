# Templates and Subtemplates are stored in the template table
# indexfile is the filename of the normally "index-file.xml"
CREATE TABLE IF NOT EXISTS template (
	uid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	name TEXT,
	indexfile TEXT
);
# All Template Properties are stored in the tmplprop TABLE
# They override the default values in the template
CREATE TABLE IF NOT EXISTS tmplprop (
    uid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT,
    section TEXT,
    type TEXT,
    value TEXT,
    templateid INTEGER
);
CREATE TABLE IF NOT EXISTS page (
    uid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT,
    visible TEXT,
    title TEXT,
    type TEXT,
    template TEXT,
    parent TEXT,
    webdir TEXT,
    filename TEXT,
    crdate DATE NOT NULL
);
CREATE TABLE IF NOT EXISTS pageitem (
    uid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT,
	visible TEXT, 
    area TEXT,
    sortid INTEGER,
    subtemplate TEXT,
    crdate DATE NOT NULL
);
CREATE TABLE IF NOT EXISTS plugin {
    uid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT,
    file TEXT,
    type TEXT,
    sortid INTEGER,
    crdate DATE NOT NULL
}