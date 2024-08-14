const { describe, it } = require('node:test')
const assert = require('assert')
const fs = require('fs')
const wasm = fs.readFileSync('./process.wasm')
const m = require(__dirname + '/process.js')


describe('Graphql Tests', async () => {
  var instance;
  const handle = async function (msg, env) {
    const res = await instance.cwrap('handle', 'string', ['string', 'string'], { async: true })(JSON.stringify(msg), JSON.stringify(env))
    console.log('Memory used:', instance.HEAP8.length)
    return JSON.parse(res)
  }

  it('Create instance', async () => {
    console.log("Creating instance...")
    var instantiateWasm = function (imports, cb) {
      WebAssembly.instantiate(wasm, imports).then(result =>

        cb(result.instance)
      )
      return {}
    }

    instance = await m({
      ARWEAVE: 'https://arweave.net',
      mode: "test",
      blockHeight: 100,
      spawn: {
        "Scheduler": "TEST_SCHED_ADDR"
      },
      Process: {
        Id: 'AOS',
        Owner: 'FOOBAR',
        tags: [
          { name: "Extension", value: "Weave-Drive" }
        ]
      },
      instantiateWasm
    })
    await new Promise((r) => setTimeout(r, 1000));
    console.log("Instance created.")
    await new Promise((r) => setTimeout(r, 250));

    assert.ok(instance)
  })


  it('Parser', async () => {
    const result = await handle(getEval(`
local duckdb = require('duckdb')

return duckdb.test(1)

  `), getEnv())
  console.log(result.response)
    assert.ok(result.response.Output.data === '1.0')
  })


});


function getEval(expr) {
  return {
    Target: 'AOS',
    From: 'FOOBAR',
    Owner: 'FOOBAR',

    Module: 'FOO',
    Id: '1',

    'Block-Height': '1000',
    Timestamp: Date.now(),
    Tags: [
      { name: 'Action', value: 'Eval' }
    ],
    Data: expr
  }
}

function getEnv() {
  return {
    Process: {
      Id: 'AOS',
      Owner: 'FOOBAR',

      Tags: [
        { name: 'Name', value: 'TEST_PROCESS_OWNER' }
      ]
    }
  }
}


// import { test } from 'node:test'
// import * as assert from 'node:assert'
// import AoLoader from '@permaweb/ao-loader'
// import fs from 'fs'

// const wasm = fs.readFileSync('./process.wasm')
// const options = { format: "wasm64-unknown-emscripten-draft_2024_02_15" }

// test('duckdb', async () => {
//     const handle = await AoLoader(wasm, options)
//     const env = {
//         Process: {
//             Id: 'AOS',
//             Owner: 'FOOBAR',
//             Tags: [
//                 { name: 'Name', value: 'Thomas' }
//             ]
//         }
//     }
//     const msg = {
//         Target: 'AOS',
//         From: 'FOOBAR',
//         Owner: 'FOOBAR',
//         ['Block-Height']: "1000",
//         Id: "1234xyxfoo",
//         Module: "WOOPAWOOPA",
//         Tags: [
//             { name: 'Action', value: 'Eval' }
//         ],
//         Data: `
// local duckdb = require('duckdb')
// return "Hello World"
// `
//     }

//     // load handler
//     const result = await handle(null, msg, env)
//     console.log(result)

//     assert.ok(true)
// })
