/* tslint:disable */
/* eslint-disable */
/**
* @returns {Promise<any>}
*/
export function state(): Promise<any>;
/**
* @param {number} num_workers
* @param {number} ms_per_benchmark
* @returns {Promise<void>}
*/
export function start(num_workers: number, ms_per_benchmark: number): Promise<void>;
/**
* @returns {Promise<void>}
*/
export function stop(): Promise<void>;
/**
* @param {string} challenge_name
* @param {string} algorithm_name
* @returns {Promise<void>}
*/
export function select_algorithm(challenge_name: string, algorithm_name: string): Promise<void>;
/**
* @param {string} api_url
* @param {string} api_key
* @param {string} player_id
* @returns {Promise<void>}
*/
export function setup(api_url: string, api_key: string, player_id: string): Promise<void>;

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
  readonly memory: WebAssembly.Memory;
  readonly state: () => number;
  readonly start: (a: number, b: number) => number;
  readonly stop: () => number;
  readonly select_algorithm: (a: number, b: number, c: number, d: number) => number;
  readonly setup: (a: number, b: number, c: number, d: number, e: number, f: number) => number;
  readonly __wbindgen_malloc: (a: number, b: number) => number;
  readonly __wbindgen_realloc: (a: number, b: number, c: number, d: number) => number;
  readonly __wbindgen_export_2: WebAssembly.Table;
  readonly _dyn_core__ops__function__FnMut_____Output___R_as_wasm_bindgen__closure__WasmClosure___describe__invoke__h8b7a3e303bfdb7ca: (a: number, b: number) => void;
  readonly _dyn_core__ops__function__FnMut__A____Output___R_as_wasm_bindgen__closure__WasmClosure___describe__invoke__hcd3c74f9bb2d4d77: (a: number, b: number, c: number) => void;
  readonly __wbindgen_exn_store: (a: number) => void;
  readonly wasm_bindgen__convert__closures__invoke2_mut__h0009c60f4de1debc: (a: number, b: number, c: number, d: number) => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;
/**
* Instantiates the given `module`, which can either be bytes or
* a precompiled `WebAssembly.Module`.
*
* @param {SyncInitInput} module
*
* @returns {InitOutput}
*/
export function initSync(module: SyncInitInput): InitOutput;

/**
* If `module_or_path` is {RequestInfo} or {URL}, makes a request and
* for everything else, calls `WebAssembly.instantiate` directly.
*
* @param {InitInput | Promise<InitInput>} module_or_path
*
* @returns {Promise<InitOutput>}
*/
export default function __wbg_init (module_or_path?: InitInput | Promise<InitInput>): Promise<InitOutput>;
