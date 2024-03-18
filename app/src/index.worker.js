import initSqlJs from '@urdeveloper/sql.js';
import { SQLiteFS } from 'absurd-sql';
import IndexedDBBackend from 'absurd-sql/dist/indexeddb-backend';

async function init() {
  let SQL = await initSqlJs({ locateFile: file => file });
  let sqlFS = new SQLiteFS(SQL.FS, new IndexedDBBackend());
  SQL.register_for_idb(sqlFS);

  SQL.FS.mkdir('/sql');
  SQL.FS.mount(sqlFS, {}, '/sql');

  const dbFile = await fetch('sim.db').then(res => res.arrayBuffer())
  const db = new SQL.Database(new Uint8Array(dbFile), {filename: '/sql/sim.db'})
  db.run('PRAGMA strict=ON')

  // db.exec(`
  //   PRAGMA page_size=8192;
  //   PRAGMA journal_mode=MEMORY;
  // `);

  return db;
}

async function runQueries() {
  let db = await init();
  db.run("select * from post")
}

runQueries();
