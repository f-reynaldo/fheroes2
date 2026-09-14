// Persist fheroes2 user configuration and save games in browser IndexedDB.
// Keep all user-writable fheroes2 files below one IDBFS mount.
Module.preRun = Module.preRun || [];
Module.preRun.push(function () {
    const persistentDirectory = '/fheroes2';

    // fheroes2's Linux path code uses HOME/XDG_CONFIG_HOME/XDG_DATA_HOME.
    // Force those paths into the IDBFS mount so configuration and saves are
    // guaranteed to be persistent rather than ending up in MEMFS.
    Object.assign(ENV, {
        HOME: persistentDirectory,
        XDG_CONFIG_HOME: persistentDirectory + '/.config',
        XDG_DATA_HOME: persistentDirectory + '/.local/share'
    });

    FS.mkdirTree(persistentDirectory);
    FS.mount(IDBFS, { root: '/', autoPersist: true }, persistentDirectory);

    addRunDependency('fheroes2-idbfs-load');
    FS.syncfs(true, function (error) {
        if (error) {
            console.error('Unable to load persistent fheroes2 data:', error);
        } else {
            console.log('Loaded persistent fheroes2 data from IndexedDB at ' + persistentDirectory);
        }
        removeRunDependency('fheroes2-idbfs-load');
    });
});
