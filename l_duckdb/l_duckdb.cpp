


#ifdef __cplusplus
  #include "lua.hpp"
#else
  #include "lua.h"
  #include "lualib.h"
  #include "lauxlib.h"
#endif
#include "duckdb.hpp"


//so that name mangling doesn't mess up function names
#ifdef __cplusplus
extern "C"{
#endif

static int l_duckdb_test (lua_State *L) {
    double arg = luaL_checknumber (L, 1);
    duckdb::DuckDB db(nullptr);
    duckdb::Connection con(db);
    // create a table
    con.Query("CREATE TABLE integers (i INTEGER, j INTEGER)");

    // insert three rows into the table
    con.Query("INSERT INTO integers VALUES (3, 4), (5, 6), (7, NULL)");

    auto result = con.Query("SELECT * FROM integers");
    int num = 0;
    if (result->HasError()) {
        num = -1;
    } else {
        num = 1;
    }
    lua_pushnumber(L, 1);
    return 1;
}

//library to be registered
static const struct luaL_Reg duckdb_funcs [] = {
      {"test", l_duckdb_test}, /* names can be different */
      {NULL, NULL}  /* sentinel */
    };

//name of this function is not flexible
int luaopen_duckdb (lua_State *L){
    luaL_newlib(L, duckdb_funcs);
    return 1;
}

#ifdef __cplusplus
}
#endif


