# Changelog

## [3.8.0](https://github.com/TrogonStack/commanded/compare/v3.7.1...v3.8.0) (2026-09-24)


### Features

* **middleware:** Add BaggagePropagator for W3C Baggage ([#108](https://github.com/TrogonStack/commanded/issues/108)) ([d0e9177](https://github.com/TrogonStack/commanded/commit/d0e9177380b96ff17de8d830f74bb341fca8e356))
* **router:** Support `causation_id: nil` to mark events as chain roots ([#106](https://github.com/TrogonStack/commanded/issues/106)) ([4da2396](https://github.com/TrogonStack/commanded/commit/4da2396b4864b136ff3d81e809df7d425e1461a7))


### Bug Fixes

* **dispatcher:** Honour `:causation_id` dispatch option on persisted events ([dba8594](https://github.com/TrogonStack/commanded/commit/dba859463e269848a78af308127a93f0276aede9))
* **handler:** Prevent a reset from corrupting the handler read model ([#110](https://github.com/TrogonStack/commanded/issues/110)) ([f2ead73](https://github.com/TrogonStack/commanded/commit/f2ead73a6680f39a4f178bf25b002643eaf11bfc))

## [3.7.1](https://github.com/TrogonStack/commanded/compare/v3.7.0...v3.7.1) (2026-05-14)


### Bug Fixes

* **dispatcher:** Honor caller-supplied :causation_id on persisted events ([#103](https://github.com/TrogonStack/commanded/issues/103)) ([13f88f3](https://github.com/TrogonStack/commanded/commit/13f88f3e427c8525b76c536f4e5b52590a481254))
* **dispatcher:** Preserve retry failure guarantees ([#96](https://github.com/TrogonStack/commanded/issues/96)) ([7a07792](https://github.com/TrogonStack/commanded/commit/7a07792542999c66d0930964b43c4c4d4704c557))
* **telemetry:** Rename commanded.handler.lag to commanded.handler.processing_latency ([#95](https://github.com/TrogonStack/commanded/issues/95)) ([8198884](https://github.com/TrogonStack/commanded/commit/8198884e5590a093baba03a92008698a0c10bcd3))
* **test:** Restore full suite projection bootstrap ([#99](https://github.com/TrogonStack/commanded/issues/99)) ([945b1cf](https://github.com/TrogonStack/commanded/commit/945b1cf19846598d2fba901061a7df747341a001))

## [3.7.0](https://github.com/TrogonStack/commanded/compare/v3.6.1...v3.7.0) (2026-04-21)


### Features

* **telemetry:** Propagate caller trace context to aggregate load spans ([#90](https://github.com/TrogonStack/commanded/issues/90)) ([9a6ee07](https://github.com/TrogonStack/commanded/commit/9a6ee0702f4a91bdba705b682c1b0bc270900c19))


### Bug Fixes

* **telemetry:** Add peer.service and DB semantic attributes to EventStore spans ([#91](https://github.com/TrogonStack/commanded/issues/91)) ([d09a91e](https://github.com/TrogonStack/commanded/commit/d09a91e60489d4b3c49a73e7e2ff5e4a74ca09fd))
* **telemetry:** Enrich EventStore spans with full OTel semantic attributes ([#92](https://github.com/TrogonStack/commanded/issues/92)) ([0d0763a](https://github.com/TrogonStack/commanded/commit/0d0763af83f2c0209f387f31fc1b231bacc670c4))
* **telemetry:** Strip Elixir. prefix from commanded.application attribute ([#93](https://github.com/TrogonStack/commanded/issues/93)) ([909c484](https://github.com/TrogonStack/commanded/commit/909c48477fb34444e29e65d0d6a9bd1669354f49))
* **test:** Keep adapter coverage aligned with EventStore semantics ([#87](https://github.com/TrogonStack/commanded/issues/87)) ([6aa37fd](https://github.com/TrogonStack/commanded/commit/6aa37fd70bd87874c9b8e3c3df2788560c34cd5c))

## [3.6.1](https://github.com/TrogonStack/commanded/compare/v3.6.0...v3.6.1) (2026-04-16)


### Bug Fixes

* **github:** Pin release-please-action to commit SHA ([#85](https://github.com/TrogonStack/commanded/issues/85)) ([15bbdc5](https://github.com/TrogonStack/commanded/commit/15bbdc5691019832207a271ed33eda11a526e47b))
* **telemetry:** Keep event store spans tied to their destination ([#83](https://github.com/TrogonStack/commanded/issues/83)) ([e4b49a7](https://github.com/TrogonStack/commanded/commit/e4b49a74b5dc13a18ea27402640285d613625e07))

## [3.6.0](https://github.com/TrogonStack/commanded/compare/v3.5.0...v3.6.0) (2026-04-16)


### Features

* **telemetry:** Add registry adapter to aggregate execute span ([#71](https://github.com/TrogonStack/commanded/issues/71)) ([fdaaa5d](https://github.com/TrogonStack/commanded/commit/fdaaa5d0b4d373f6a01efd1349fe6156162c76b0))
* **telemetry:** Keep returned command errors out of failed spans ([#82](https://github.com/TrogonStack/commanded/issues/82)) ([f586f58](https://github.com/TrogonStack/commanded/commit/f586f58d8ba284081a0ff9b4e7ae629d7518134f))


### Bug Fixes

* **dispatch:** Reduce drift in the public return contract ([#74](https://github.com/TrogonStack/commanded/issues/74)) ([0813343](https://github.com/TrogonStack/commanded/commit/0813343e3460649744d4876ca6b7b7c60088405d))
* **dispatch:** Reject invalid command UUID overrides ([#75](https://github.com/TrogonStack/commanded/issues/75)) ([195a12b](https://github.com/TrogonStack/commanded/commit/195a12ba90029250d39e4af88ba57fdf094859bc))
* **subscriptions:** Avoid races in teardown assertions ([#80](https://github.com/TrogonStack/commanded/issues/80)) ([91a612f](https://github.com/TrogonStack/commanded/commit/91a612ff7fee4cb42f9fe0618b4baf853d269e27))
* **telemetry:** Isolate test OpenTelemetry configuration ([#79](https://github.com/TrogonStack/commanded/issues/79)) ([2b0a739](https://github.com/TrogonStack/commanded/commit/2b0a739680f04823b70de7b28843d3441f97ac4d))
* **test:** Keep projection setup out of unrelated runs ([#81](https://github.com/TrogonStack/commanded/issues/81)) ([ea80428](https://github.com/TrogonStack/commanded/commit/ea804280f5d54a930ac4302460dc6aea06649c4f))
* **types:** Align execution result metadata with dispatch contract ([#77](https://github.com/TrogonStack/commanded/issues/77)) ([2ebcd07](https://github.com/TrogonStack/commanded/commit/2ebcd07d42fd17132347ec98beac4e1e21ce86da))
* **types:** Keep failure context strict ([#78](https://github.com/TrogonStack/commanded/issues/78)) ([47db0d2](https://github.com/TrogonStack/commanded/commit/47db0d20e290e084323e4daeb63939c584a25916))
* **types:** Prevent invalid dispatch metadata from bypassing Dialyzer ([#73](https://github.com/TrogonStack/commanded/issues/73)) ([495f886](https://github.com/TrogonStack/commanded/commit/495f886a1619e3b2ae5d763554553693abf118ab))
* **types:** Strengthen dispatch struct contracts for Dialyzer ([#76](https://github.com/TrogonStack/commanded/issues/76)) ([c677d4c](https://github.com/TrogonStack/commanded/commit/c677d4c6d9b9f9a0873121631893d7ce5db963f7))

## [3.5.0](https://github.com/TrogonStack/commanded/compare/v3.4.1...v3.5.0) (2026-04-05)


### Features

* **telemetry:** Add aggregate_module to load/populate/snapshot telemetry metadata ([#69](https://github.com/TrogonStack/commanded/issues/69)) ([78bcfe7](https://github.com/TrogonStack/commanded/commit/78bcfe73940c49a1e8650292afabaac5f8d26962))
* **telemetry:** Add and surface processing_latency_ms in event handler spans ([#68](https://github.com/TrogonStack/commanded/issues/68)) ([ffaafcf](https://github.com/TrogonStack/commanded/commit/ffaafcf472c8f98d398bf202550c070adf77b1d2))
* **telemetry:** Add processing_latency_ms to event handler stop measurements ([#66](https://github.com/TrogonStack/commanded/issues/66)) ([edbe23e](https://github.com/TrogonStack/commanded/commit/edbe23e2528ac23f8c7e7c7bd3bea32ab7cd6f4a))

## [3.4.1](https://github.com/TrogonStack/commanded/compare/v3.4.0...v3.4.1) (2026-04-01)


### Bug Fixes

* **event_store:** Defer stream_forward telemetry until stream consumed ([#64](https://github.com/TrogonStack/commanded/issues/64)) ([588b801](https://github.com/TrogonStack/commanded/commit/588b8014c0803b0463ebb8a5dab47492df128e5a))

## [3.4.0](https://github.com/TrogonStack/commanded/compare/v3.3.2...v3.4.0) (2026-03-13)


### Features

* Add OpenTelemetry support for aggregate snapshots ([#60](https://github.com/TrogonStack/commanded/issues/60)) ([d651288](https://github.com/TrogonStack/commanded/commit/d651288ad026ff9f08becbdde6203861350bc2ff))
* Add wrong_expected_version span event to aggregate execute OTel ([#61](https://github.com/TrogonStack/commanded/issues/61)) ([f1f8b1b](https://github.com/TrogonStack/commanded/commit/f1f8b1ba82a55a5a9e429e2218f4d63c548612eb))


### Bug Fixes

* Emit populate telemetry for new aggregates (stream_not_found) ([#58](https://github.com/TrogonStack/commanded/issues/58)) ([1af575a](https://github.com/TrogonStack/commanded/commit/1af575a28722585a6375c309b27e8d905014b273))

## [3.3.2](https://github.com/TrogonStack/commanded/compare/v3.3.1...v3.3.2) (2026-02-27)


### Bug Fixes

* Enable event store OpenTelemetry tracing by default ([#56](https://github.com/TrogonStack/commanded/issues/56)) ([642ab64](https://github.com/TrogonStack/commanded/commit/642ab64131d7ff0540924051e5118185ee06ee84))

## [3.3.1](https://github.com/TrogonStack/commanded/compare/v3.3.0...v3.3.1) (2026-02-26)


### Bug Fixes

* Use Broadway/Oban pattern for OTel context propagation ([4185ca1](https://github.com/TrogonStack/commanded/commit/4185ca1da3997de7a7a2813e6943b154172a34ac))

## [3.3.0](https://github.com/TrogonStack/commanded/compare/v3.2.0...v3.3.0) (2026-02-23)


### Features

* Add selector option support for InMemory adapter ([625f54b](https://github.com/TrogonStack/commanded/commit/625f54b3dccab031ceabfe1aeca7e409170e7f4f))


### Bug Fixes

* Check for duplicates before popping from keyword list ([d4dcbdc](https://github.com/TrogonStack/commanded/commit/d4dcbdc3bb5f2af2f54c2e52a7b1a7b96d5cd41e))
* Improve router registration error messages ([124f4f4](https://github.com/TrogonStack/commanded/commit/124f4f4ff8113d721f793ee667e90191b22ab117))
* Raise ArgumentError instead of RuntimeError for router config errors ([a0add7f](https://github.com/TrogonStack/commanded/commit/a0add7f49c55a8419e9372662faf41e351ae8bc9))
* Reject duplicate dispatch options in router ([582f9da](https://github.com/TrogonStack/commanded/commit/582f9da58a6878c9f1c27c7f89d18c945577bffe))
* Update release-please workflow to match beam-monorepo config ([27981f6](https://github.com/TrogonStack/commanded/commit/27981f671d9024059ed63a3ebeebf60994575f9b))

## [3.2.0](https://github.com/TrogonStack/commanded/compare/v3.1.0...v3.2.0) (2026-01-23)


### Features

* add OpenTelemetry EventStore instrumentation ([#37](https://github.com/TrogonStack/commanded/issues/37)) ([6bb4b00](https://github.com/TrogonStack/commanded/commit/6bb4b0074423daf4a8a823279fa14ab4c604f613))
* Add OpenTelemetry instrumentation for aggregate populate ([#47](https://github.com/TrogonStack/commanded/issues/47)) ([f7b43d1](https://github.com/TrogonStack/commanded/commit/f7b43d1bbc2ab1efe9d9eda2961f2f669721f48b))
* Add OpenTelemetry instrumentation for event handlers ([#41](https://github.com/TrogonStack/commanded/issues/41)) ([5946d5a](https://github.com/TrogonStack/commanded/commit/5946d5ab1957e1a641ed983b8bfeefe08e92e7fb))
* implement OpenTelemetry instrumentation for aggregates ([#45](https://github.com/TrogonStack/commanded/issues/45)) ([4e99401](https://github.com/TrogonStack/commanded/commit/4e9940165dd59f0d08e53e48d01b6f112c3e0660))
* implement OpenTelemetry instrumentation for application ([#46](https://github.com/TrogonStack/commanded/issues/46)) ([a4bc0fd](https://github.com/TrogonStack/commanded/commit/a4bc0fd8722c7d16907f57ff80f527f0f1153178))

## [3.1.0](https://github.com/TrogonStack/commanded/compare/v3.0.0...v3.1.0) (2026-01-13)


### Features

* add aggregate identity handling to use `Commanded.Aggregate.Identity` protocol ([#43](https://github.com/TrogonStack/commanded/issues/43)) ([a0eb2cb](https://github.com/TrogonStack/commanded/commit/a0eb2cb982958bad29d6905af3ad4e477efa05fb))
* add W3C Trace Context propagation middleware for OpenTelemetry ([#38](https://github.com/TrogonStack/commanded/issues/38)) ([b6c3e0b](https://github.com/TrogonStack/commanded/commit/b6c3e0b830a0572748134fa81de9ce5447364dd1))

## [3.0.0](https://github.com/TrogonStack/commanded/compare/v2.1.0...v3.0.0) (2025-11-21)


### ⚠ BREAKING CHANGES

* remove deprecated init/0 callback and atom metadata key ([#35](https://github.com/TrogonStack/commanded/issues/35))
* remove deprecated project macros in Ecto projections ([#31](https://github.com/TrogonStack/commanded/issues/31))
* remove upcast ([#26](https://github.com/TrogonStack/commanded/issues/26))
* remove process manager ([#24](https://github.com/TrogonStack/commanded/issues/24))

### Features

* add batch support to Ecto projections ([#30](https://github.com/TrogonStack/commanded/issues/30)) ([0fb29d6](https://github.com/TrogonStack/commanded/commit/0fb29d6e4213a87158e45e028f8b45e093d60ef0))
* add Commanded.Projections.Ecto ([#27](https://github.com/TrogonStack/commanded/issues/27)) ([d7bdcce](https://github.com/TrogonStack/commanded/commit/d7bdcce33f32e61a1ec4ddfcb6decb24a81a995e))
* add support for UUIDv7 generation and update command options to use UUIDv7 ([#22](https://github.com/TrogonStack/commanded/issues/22)) ([bb29716](https://github.com/TrogonStack/commanded/commit/bb297164b97e452b44d138ae3b412f26bd1d55c2))
* implement timezone-aware timestamps for projections ([#32](https://github.com/TrogonStack/commanded/issues/32)) ([af1bb2c](https://github.com/TrogonStack/commanded/commit/af1bb2cb6651a0a1ea9b79142cb8a8413137981a))


### Bug Fixes

* add concurrency validation for Ecto projections ([#33](https://github.com/TrogonStack/commanded/issues/33)) ([50ec412](https://github.com/TrogonStack/commanded/commit/50ec4128f9d684bd33820b527e2320f7f788caff))
* remove process manager ([#24](https://github.com/TrogonStack/commanded/issues/24)) ([fbe7479](https://github.com/TrogonStack/commanded/commit/fbe74793f4527f1f73f5beb0e6b08fc27b9049c1))
* remove upcast ([#26](https://github.com/TrogonStack/commanded/issues/26)) ([9d03039](https://github.com/TrogonStack/commanded/commit/9d03039812ae934f2177f17e435ddbc59bb804ee))


### Miscellaneous Chores

* remove deprecated init/0 callback and atom metadata key ([#35](https://github.com/TrogonStack/commanded/issues/35)) ([4762803](https://github.com/TrogonStack/commanded/commit/47628032d9cba32bd21a07a5d6e424dea686e836))
* remove deprecated project macros in Ecto projections ([#31](https://github.com/TrogonStack/commanded/issues/31)) ([2c552e8](https://github.com/TrogonStack/commanded/commit/2c552e80a6daa48b901f243263758c77c1410514))

## [2.1.0](https://github.com/TrogonStack/commanded/compare/v2.0.0...v2.1.0) (2025-08-30)


### Features

* Add aggregate behaviour ([31337cb](https://github.com/TrogonStack/commanded/commit/31337cbb7f93b7c7ac77b8a33dae0285ffe492d5))
* add batch support ([#18](https://github.com/TrogonStack/commanded/issues/18)) ([b593f04](https://github.com/TrogonStack/commanded/commit/b593f040bca4ddedc29f0787d82f484aa699d196))
* add configurable UUID provider using Uniq.UUID ([deb4f8f](https://github.com/TrogonStack/commanded/commit/deb4f8ffe0d33a24cbe8e55d2584bd8af2047924))


### Bug Fixes

* make take snapshot sync call ([#20](https://github.com/TrogonStack/commanded/issues/20)) ([57d0b6a](https://github.com/TrogonStack/commanded/commit/57d0b6a118dfd218b7656d35daa6aaee5b322eae))

## [2.0.0](https://github.com/TrogonStack/commanded/compare/v1.6.0...v2.0.0) (2025-05-30)


### ⚠ BREAKING CHANGES

* introduce EnrichedMetadata struct for enhanced event metadata handling ([#11](https://github.com/TrogonStack/commanded/issues/11))

### Features

* add serializer behaviour ([#14](https://github.com/TrogonStack/commanded/issues/14)) ([fa81870](https://github.com/TrogonStack/commanded/commit/fa818701e437f36e2f3afe6732b39f117b034d19))
* introduce EnrichedMetadata struct for enhanced event metadata handling ([#11](https://github.com/TrogonStack/commanded/issues/11)) ([7772579](https://github.com/TrogonStack/commanded/commit/77725791c7f10667baec4e76bd6f16983f52b118))

## [1.6.0](https://github.com/TrogonStack/commanded/compare/v1.5.0...v1.6.0) (2025-05-19)


### Features

* add telemetry for wrong expected version in aggregates ([#8](https://github.com/TrogonStack/commanded/issues/8)) ([fe41c8a](https://github.com/TrogonStack/commanded/commit/fe41c8ac971920fb9cfafb4dbd9fdf8d7b1286b0))

## v1.5.0

### Enhancements

- Add `Commanded.Event.EventId` protocol.

## v1.4.8

### Bug fixes

- `Commanded.Event.ErrorHandler` now keeps surounding failure context by @drteeth in https://github.com/commanded/commanded/issues/617

## v1.4.7

### Enhancements

- Application-wide event handler error handling by @drteeth in https://github.com/commanded/commanded/pull/605
- chore: remove asdf file by @yordis in https://github.com/commanded/commanded/pull/570
- chore: improve docs about aggregate version by @yordis in https://github.com/commanded/commanded/pull/608
- Update include_aggregate_version documentation by @TylerPachal in https://github.com/commanded/commanded/pull/609

### Bug fixes

- Fix flakey test by @drteeth in https://github.com/commanded/commanded/pull/599
- feat: default aggregate lifespan configuration by @yordis in https://github.com/commanded/commanded/pull/548
- Aggregate.handle\_\* now properly handles lifespans by @drteeth in https://github.com/commanded/commanded/pull/606
- Allow registration handle_call/cast callbacks to be called by @drteeth in https://github.com/commanded/commanded/pull/607
- Update local_cluster by @drteeth in https://github.com/commanded/commanded/pull/610

## v1.4.6

### Enhancements

- Includes changelog updates
- Version bump

## v1.4.5

### Enhancements

- Support OTP 26 and Elixir 1.17 ([#595](https://github.com/commanded/commanded/pull/595)).

## v1.4.4

### Enhancements

- feat: put aggregate_state into assigns of the pipeline ([#502](https://github.com/commanded/commanded/pull/502)).
- Add tag to partition test case ([#525](https://github.com/commanded/commanded/pull/525)).
- Make before_reset/0 an explicit callback function ([#550](https://github.com/commanded/commanded/pull/550)).
- New `Event.Handler.after_start/1` callback allows configuration in the handler's process ([#568](https://github.com/commanded/commanded/pull/568)).

### Bug fixes

- Fix EventData typespec ([#495](https://github.com/commanded/commanded/pull/495)).
- Fix refute_receive_event examples ([#557](https://github.com/commanded/commanded/pull/557)).
- Fix interested? function doc ([#562](https://github.com/commanded/commanded/pull/562)).
- Use TypeProvider for process managers snapshot serialization ([#558](https://github.com/commanded/commanded/pull/558)).
- fix(router.ex): Telemetry is not emitted if dispatch fails for {:error, :unregistered_command} ([#563](in https://github.com/commanded/commanded/pull/563)).

## v1.4.3

### Enhancements

- Use `Logger.warning` to fix deprecation warnings ([#542](https://github.com/commanded/commanded/pull/542)).
- Add typespec to `CompositeRouter.dispatch/2` function ([#536](https://github.com/commanded/commanded/pull/536)).
- Support `opts` in `Commanded.EventStore.append_to_stream` function ([#528](https://github.com/commanded/commanded/pull/528)).
- Process manager metadata access ([#514](https://github.com/commanded/commanded/pull/514)).

### Bug fixes

- Correct parameter type in `ProcessManager.after_command/1` callback function ([#533](https://github.com/commanded/commanded/pull/533)).

## v1.4.2

- Record aggregate state while processing `Commanded.Aggregate.Multi` ([#507](https://github.com/commanded/commanded/pull/507)).
- Properly handle EXIT signal in event handler ([#512](https://github.com/commanded/commanded/pull/512)).
- Separate logging a process managers error ([#513](https://github.com/commanded/commanded/pull/513)).

## v1.4.1

### Enhancements

- Retry command execution when the aggregate process is down ([#494](https://github.com/commanded/commanded/pull/494)).

### Bug fixes

- Remove duplicate apply function call when receiving missed events published to an aggregate's event stream ([364c877](https://github.com/commanded/commanded/commit/364c877e8f30a18d90544676fb58b94132d50720)).
- Fix typespec typo in Commanded.Application ([#503](https://github.com/commanded/commanded/pull/503)).

## v1.4.0

### Enhancements

- Allow a process manager to stop after dispatching a command ([#460](https://github.com/commanded/commanded/pull/460)).
- Replace `use Mix.Config` with `import Config` in config files ([#467](https://github.com/commanded/commanded/pull/467)).
- Event handler concurrency ([#486](https://github.com/commanded/commanded/pull/486)).
- Remove `elixir_uuid` dependency ([#493](https://github.com/commanded/commanded/pull/493)).
- Support and test for OTP 25 ([#489](https://github.com/commanded/commanded/pull/489)).

---

## v1.3.1

### Bug fixes

- Event Handler not calling `init/1` callback function on restart ([#463](https://github.com/commanded/commanded/pull/463)).
- Call process manager `init/1` function on process restart ([#464](https://github.com/commanded/commanded/pull/464)).

## v1.3.0

### Enhancements

- Allow command identity to be provided during dispatch ([#406](https://github.com/commanded/commanded/pull/406)).
- Define `Commanded.Telemetry` module to emit consistent telemetry events ([#414](https://github.com/commanded/commanded/pull/414)).
- Telemetry `[:commanded, :aggregate, :execute]` events ([#407](https://github.com/commanded/commanded/pull/407)).
- Telemetry `[:commanded, :event, :handle]` events ([#408](https://github.com/commanded/commanded/pull/408)).
- Telemetry `[:commanded, :process_manager, :handle]` events ([#418](https://github.com/commanded/commanded/pull/418)).
- Telemetry `[:commanded, :application, :dispatch]` ([#423](https://github.com/commanded/commanded/pull/423)).
- Graceful shutdown of event handlers ([#431](https://github.com/commanded/commanded/pull/431)).
- Ensure command dispatch metadata is a map ([#432](https://github.com/commanded/commanded/pull/432)).
- Retry command execution on node down ([#429](https://github.com/commanded/commanded/pull/429)).
- Dispatch returning resultant events ([#444](https://github.com/commanded/commanded/pull/444)).
- Get aggregate state ([#448](https://github.com/commanded/commanded/pull/448)).
- Support telemetry v1.0 ([#456](https://github.com/commanded/commanded/pull/456)).

## v1.2.0

### Enhancements

- Add `init/1` callback function to event handlers and process managers ([#393](https://github.com/commanded/commanded/pull/393)).
- Include `application` and `handler_name` as additional event handler metadata ([#396](https://github.com/commanded/commanded/pull/396)).
- Allow `GenServer` start options to be provided when starting event handlers and process managers ([#398](https://github.com/commanded/commanded/pull/398)).
- Add `hibernate_after` option to application config ([#399](https://github.com/commanded/commanded/pull/399)).
- Add support for providing adapter-specific event store subscription options ([#391](https://github.com/commanded/commanded/pull/391)).
- Support custom state for event handlers ([#400](https://github.com/commanded/commanded/pull/400)).
- Allow event handlers and process manager `error` callback to return failure context struct ([#397](https://github.com/commanded/commanded/issues/397)).
- Allow a before execute function to be defined which is called with the command dispatch execution context and aggregate state before ([#402](https://github.com/commanded/commanded/pull/402)).

### Bug fixes

- Allow process manager `error/3` callback to return `:skip` for failed commands, not just failed events ([#362](https://github.com/commanded/commanded/issues/362)).

---

## v1.1.1

### Enhancements

- Capture exception on Process Manager `apply/2` and call `error/3` callback functions ([#380](https://github.com/commanded/commanded/pull/380)).
- Include metadata in upcaster protocol ([#389](https://github.com/commanded/commanded/pull/389)).

### Bug fixes

- Fix `Commanded.Aggregate.Multi.execute/2` calls which return ` Multi` struct ([#385](https://github.com/commanded/commanded/pull/385])).

## v1.1.0

### Enhancements

- Dynamic Commanded applications ([#324](https://github.com/commanded/commanded/pull/324)).
- Log and ignore unexpected messages received by event handlers and process manager instances ([#333](https://github.com/commanded/commanded/pull/333))
- Process manager `identity/0` function ([#334](https://github.com/commanded/commanded/pull/334)).
- Extend `Commanded.AggregateCase` ExUnit case template to support `Commanded.Aggregate.Multi`.
- Allow `Commanded.Aggregate.Multi` to return events as `:ok` tagged tuples.
- Run the formatter in CI ([#341](https://github.com/commanded/commanded/pull/341)).
- Add stacktraces to EventHandler error logging ([#340](https://github.com/commanded/commanded/pull/340))
- `refute_receive_event/4` only tests newly created events ([#347](https://github.com/commanded/commanded/pull/347)).
- Allow Commanded Application name to be set dynamically in middleware ([#352](https://github.com/commanded/commanded/pull/352)).
- Remove router module compile-time checking ([#363](https://github.com/commanded/commanded/pull/363)).
- Reduce memory consumption during aggregate state rebuild ([#368](https://github.com/commanded/commanded/pull/368)).
- Upgrade to `phoenix_pubsub` to 2.0 ([#365](https://github.com/commanded/commanded/pull/365)).
- Ignore `:not_found` error when resetting InMemory event store ([#354](https://github.com/commanded/commanded/pull/354)).
- Add `router/1` to `locals_without_parens` in Mix format config ([#351](https://github.com/commanded/commanded/pull/351)).
- Include stacktrace in event handler and process manager `error` callback functions ([#342](https://github.com/commanded/commanded/pull/342)).
- Call event handler's `error/3` callback function when `handle/2` function returns an invalid value ([#372](https://github.com/commanded/commanded/pull/372)).

### Bug fixes

- Fixes the typespec for command dispatch ([#325](https://github.com/commanded/commanded/pull/325)).
- Process manager stops if `interested?/1` returns an empty list ([#335](https://github.com/commanded/commanded/pull/335)).

---

## v1.0.1

### Enhancements

- Global registry using Erlang's `:global` module ([#344](https://github.com/commanded/commanded/pull/344)).
- Command dispatch return ([#331](https://github.com/commanded/commanded/pull/331)).

### Bug fixes

- Fix distributed subscription registration bug ([#345](https://github.com/commanded/commanded/pull/345)).
- Retry event handler and process manager subscriptions on error ([#348](https://github.com/commanded/commanded/pull/348)).

## v1.0.0

### Breaking changes

- Support multiple Commanded apps ([#298](https://github.com/commanded/commanded/pull/298)).

### Enhancements

- Define adapter behaviour modules for event store, pubsub, and registry ([#311](https://github.com/commanded/commanded/pull/311)).
- Add `AggregateCase` ExUnit case template to support aggregate unit testing ([#315](https://github.com/commanded/commanded/pull/315)).
- Application config lookup ([#318](https://github.com/commanded/commanded/pull/318)).

### Bug fixes

- Fix process manager exception on start ([#307](https://github.com/commanded/commanded/pull/307)).
- Fix commanded aggregate race ([#308](https://github.com/commanded/commanded/pull/308)).
- Fix Dialyzer warnings and include in Travis CI ([#317](https://github.com/commanded/commanded/pull/317)).

### Upgrading

[Follow the upgrade guide](https://hexdocs.pm/commanded/1.0.0/0.19-1.0.html) to define and use your own Commanded application.

---

## v0.19.1

### Enhancements

- Reset event handler mix task `mix commanded.reset MyApp.Handler` ([#293](https://github.com/commanded/commanded/pull/293)).

### Bug fixes

- Fix regression in `Commanded.Middleware.Logger.delta` ([#295](https://github.com/commanded/commanded/pull/295)).

## v0.19.0

### Enhancements

- Update typespec for `data` and `metadata` fields in `Commanded.EventStore.EventData` struct ([#246](https://github.com/commanded/commanded/pull/246)).
- Add `include_execution_result` and `aggregate_version` to typespec for router command dispatch ([#262](https://github.com/commanded/commanded/pull/262)).
- Add `.formatter.exs` to Hex package ([#247](https://github.com/commanded/commanded/pull/247)).
- Event upcasting ([#263](https://github.com/commanded/commanded/pull/263)).
- Support `:ok` tagged tuple events from aggregate ([#268](https://github.com/commanded/commanded/pull/268)).
- Modify `Commanded.Registration.start_child` to pass a child_spec ([#273](https://github.com/commanded/commanded/pull/273)).
- Add `supervisor_child_spec/2` to `Commanded.Registration` behaviour ([#277](https://github.com/commanded/commanded/pull/277)) used by [Commanded Horde Registry](https://github.com/uberbrodt/commanded_horde_registry).
- Ensure Commanded can be compiled when optional Jason dependency is not present ([#286](https://github.com/commanded/commanded/pull/286)).
- Fix Aggregate initialization races ([#287](https://github.com/commanded/commanded/pull/287)).
- Support `{:system, varname}` format in Phoenix PubSub config ([#291](https://github.com/commanded/commanded/pull/291)).

### Breaking changes

- Use `DateTime` instead of `NaiveDateTime` for all datetimes ([#254](https://github.com/commanded/commanded/pull/254)).

  This affects the `created_at` field defined in the `Commanded.EventStore.RecordedEvent`. You will need to migrate from `NaiveDateTime` to `DateTime` if you use this field in your code (such as in an event handler's metadata).

---

## v0.18.1

### Enhancements

- Process manager idle process timeout ([#290](https://github.com/commanded/commanded/pull/290)).
- Register event handler and process manager subscriptions on process start ([#272](https://github.com/commanded/commanded/pull/272)).

## v0.18.0

### Enhancements

- Rename `uuid` dependency to `elixir_uuid` ([#178](https://github.com/commanded/commanded/pull/178)).
- Allow aggregate identity to be of any type that implements the `String.Chars` protocol ([#166](https://github.com/commanded/commanded/pull/166)).
- Process manager and event handler error & exception handling ([#192](https://github.com/commanded/commanded/pull/192)).
- Process manager event handling timeout ([#193](https://github.com/commanded/commanded/pull/193)).
- Allow event handlers to subscribe to individual streams ([#203](https://github.com/commanded/commanded/pull/203)).
- Add new values for `expected_version` for event store append events behaviour ([#127](https://github.com/commanded/commanded/pull/127)).
- Export `Commanded.Commands.Router` macros in `.formatter.exs` file ([#204](https://github.com/commanded/commanded/pull/204)).
- Generate specs and docs for Router dispatch functions only once ([#206](https://github.com/commanded/commanded/pull/206)).
- Allow two-arity predicate function in `wait_for_event` receiving both event data and recorded event struct ([#213](https://github.com/commanded/commanded/pull/213)).
- Allow `:infinity` timeout on command dispatch ([#227](https://github.com/commanded/commanded/pull/227))
- Strict process manager routing ([#243](https://github.com/commanded/commanded/pull/243)).
- Allow `Commanded.Aggregate.Multi` to be nested ([#244](https://github.com/commanded/commanded/pull/244)).
- Add `child_spec/0` function to `Commanded.EventStore` behaviour.
- Add `delete_subscription/2` to `Commanded.EventStore` behaviour ([#245](https://github.com/commanded/commanded/pull/245)).
- Add `refute_receive_event/2` to `Commanded.Assertions.EventAssertions` test helpers.

### Bug fixes

- Fix typo in `include_execution_result` global router option ([#216](https://github.com/commanded/commanded/pull/216)).
- Handle the `{:ok, _}` tuple dispatch result in process manager command dispatch ([#236](https://github.com/commanded/commanded/pull/236)).
- Allow string keys for `Commanded.Middleware.Pipeline.assign_metadata/3`, atoms are being deprecated ([#228](https://github.com/commanded/commanded/pull/228))
- Fix `Commanded.PubSub.subscribe` typespec ([#222](https://github.com/commanded/commanded/pull/222)).

### Breaking changes

- Migrate to [Jason](https://hex.pm/packages/jason) for JSON serialization ([#234](https://github.com/commanded/commanded/pull/234)).

  You will need to add Jason as a dependency in `mix.exs`:

  ```elixir
  defp deps do
    [{:jason, "~> 1.2"}]
  end
  ```

  Jason has _no support_ for encoding arbitrary structs - explicit implementation of the `Jason.Encoder` protocol is always required. You _must_ update all your domain event modules, aggregate state (when using state snapshotting), and process manager state to include `@derive Jason.Encoder` as shown below:

  ```elixir
  defmodule AnEvent do
    @derive Jason.Encoder
    defstruct [:field]
  end
  ```

- Extend aggregate lifespan behaviour to include `after_error/1` and `after_command/1` callbacks ([#210](https://github.com/commanded/commanded/pull/210)).

  Previously you only had to define an `after_event/1` callback function to implement the `Commanded.Aggregates.AggregateLifespan` behaviour:

  ```elixir
  defmodule BankAccountLifespan do
    @behaviour Commanded.Aggregates.AggregateLifespan

    def after_event(%BankAccountClosed{}), do: :stop
    def after_event(_event), do: :infinity
  end
  ```

  Now you must also define `after_command/1` and `after_error/1` callback functions:

  ```elixir
  defmodule BankAccountLifespan do
    @behaviour Commanded.Aggregates.AggregateLifespan

    def after_event(%BankAccountClosed{}), do: :stop
    def after_event(_event), do: :infinity

    def after_command(%CloseAccount{}), do: :stop
    def after_command(_command), do: :infinity

    def after_error(:invalid_initial_balance), do: :stop
    def after_error(_error), do: :stop
  end
  ```

### Upgrading

Please ensure you upgrade the following event store dependencies.

Using the Elixir [EventStore](https://github.com/commanded/eventstore):

- `eventstore` to [v0.16.0](https://hex.pm/packages/eventstore)
- `commanded_eventstore_adapter` to [v0.5.0](https://hex.pm/packages/commanded_eventstore_adapter)

Using [EventStoreDB](https://www.eventstore.com/):

- `commanded_extreme_adapter` to [v0.6.0](https://hex.pm/packages/commanded_extreme_adapter)

Commanded Ecto projections:

- `commanded_ecto_projections` to [v0.8.0](https://hex.pm/packages/commanded_ecto_projections)

Commanded scheduler:

- `commanded_scheduler` to [v0.2.0](https://hex.pm/packages/commanded_scheduler)

---

## v0.17.5

### Enhancements

- Process manager idle process timeout ([#290](https://github.com/commanded/commanded/pull/290)).

## v0.17.4

### Bug fixes

- Register event handler and process manager subscriptions on process start ([#272](https://github.com/commanded/commanded/pull/272)).

## v0.17.3

### Bug fixes

- Fix snapshot recording ([#196](https://github.com/commanded/commanded/pull/196)).
- Fixed warning about deprecated time unit in elixir 1.8 ([#239](https://github.com/commanded/commanded/pull/239)).

## v0.17.2

### Enhancements

- Remove default `error/4` callback function from process manager to silence deprecation warning.

## v0.17.1

### Enhancements

- Support `Phoenix.PubSub` v1.1.0.

### Bug fixes

- Set default aggregate lifespan timeout to `:infinity` ([#200](https://github.com/commanded/commanded/pull/200)).

## v0.17.0

### Enhancements

- Ability to globally override `include_execution_result` and `include_aggregate_version` in environment config ([#168](https://github.com/commanded/commanded/pull/168)).
- Handle custom type serialization in snapshot source type ([#165](https://github.com/commanded/commanded/pull/165)).
- Fix compiler warnings in generated code (routers, event handlers, and process managers).
- Add `InMemory.reset!/0` for testing purposes ([#175](https://github.com/commanded/commanded/pull/175)).

### Bug fixes

- Ensure process managers can be configured with `:strong` consistency.
- Fix error when subscription process already tracked ([#180](https://github.com/commanded/commanded/pull/180)).

---

## v0.16.0

- Support composite command routers ([#111](https://github.com/commanded/commanded/pull/111)).
- Aggregate state snapshots ([#121](https://github.com/commanded/commanded/pull/121)).
- New `error/3` callback for process manager and deprecated `error/4` ([#124](https://github.com/commanded/commanded/pull/124))
- Router support for identity prefix function.
- Retry command execution on concurrency error ([#132](https://github.com/commanded/commanded/pull/132)).
- Event handler `error/3` callback ([#133](https://github.com/commanded/commanded/pull/133)).
- Support distributed dispatch consistency ([#135](https://github.com/commanded/commanded/pull/135)).
- Defer event handler and process router init until after subscribed ([#138](https://github.com/commanded/commanded/pull/138)).
- Replace aggregate lifespan `after_command/1` callback with `after_event/1` ([#139](https://github.com/commanded/commanded/issues/139)).
- Support process manager routing to multiple instances ([#141](https://github.com/commanded/commanded/pull/141)).
- Allow a default consistency to be set via the application env ([#150](https://github.com/commanded/commanded/pull/150)).
- Command dispatch consistency using explicit handler names ([#161](https://github.com/commanded/commanded/pull/161)).

### Breaking changes

- The `Commanded.Aggregates.AggregateLifespan` behaviour has been changed from `after_command/1` to `after_event/1`. You will need to update your own lifespan modules to use events instead of commands to shutdown an aggregate process after an inactivity timeout.

### Upgrading

Please ensure you upgrade the following event store dependencies.

Using the Elixir [EventStore](https://github.com/commanded/eventstore):

- `eventstore` to [v0.14.0](https://hex.pm/packages/eventstore)
- `commanded_eventstore_adapter` to [v0.4.0](https://hex.pm/packages/commanded_eventstore_adapter)

Using [EventStoreDB](https://www.eventstore.com/):

- `commanded_extreme_adapter` to [v0.5.0](https://hex.pm/packages/commanded_extreme_adapter)

---

## v0.15.1

### Bug fixes

- Event handler `child_spec/1` must include config options defined by use macro.

## v0.15.0

### Enhancements

- Process manager command dispatch error handling ([#93](https://github.com/commanded/commanded/issues/93)).
- Event handlers may define an `init/0` callback function to start any related processes. It must return `:ok`, otherwise the handler process will be stopped.
- Add `include_execution_result` option to command dispatch ([#96](https://github.com/commanded/commanded/pull/96)).
- Add `Commanded.Aggregate.Multi` ([#98](https://github.com/commanded/commanded/pull/98)) as a way to return multiple events from a command dispatch that require aggregate state to be updated after each event.
- Correlation and causation ids ([#105](https://github.com/commanded/commanded/pull/105)).
- Initial support for running on a cluster of nodes ([#80](https://github.com/commanded/commanded/pull/80)).

### Bug fixes

- Adding a prefix to the aggregate in the router breaks the strong consistency of command dispatch ([#101](https://github.com/commanded/commanded/issues/101)).

### Upgrading

Please ensure you upgrade the following event store dependencies.

Using the Elixir [EventStore](https://github.com/commanded/eventstore):

- `eventstore` to [v0.13.0](https://hex.pm/packages/eventstore)
- `commanded_eventstore_adapter` to [v0.3.0](https://hex.pm/packages/commanded_eventstore_adapter)

Using [EventStoreDB](https://www.eventstore.com/):

- `commanded_extreme_adapter` to [v0.4.0](https://hex.pm/packages/commanded_extreme_adapter)

---

## v0.14.0

### Enhancements

- Dispatch command with `:eventual` or `:strong` consistency guarantee ([#82](https://github.com/commanded/commanded/issues/82)).
- Additional stream prefix per aggregate ([#77](https://github.com/commanded/commanded/issues/77)).
- Include custom metadata during command dispatch ([#61](https://github.com/commanded/commanded/issues/61)).
- Validate command dispatch registration in router ([59](https://github.com/commanded/commanded/issues/59)).

### Upgrading

Please ensure you upgrade the following event store dependencies.

Using the Elixir [EventStore](https://github.com/commanded/eventstore):

- `eventstore` to [v0.11.0](https://hex.pm/packages/eventstore)
- `commanded_eventstore_adapter` to [v0.2.0](https://hex.pm/packages/commanded_eventstore_adapter)

Using [EventStoreDB](https://www.eventstore.com/):

- `commanded_extreme_adapter` to [v0.3.0](https://hex.pm/packages/commanded_extreme_adapter)

---

## v0.13.0

### Enhancements

- Command dispatch optionally returns aggregate version, using `include_aggregate_version: true` during dispatch.

---

## v0.12.0

### Enhancements

- `Commanded.Event.Handler` and `Commanded.ProcessManagers.ProcessManager` macros to simplify defining, and starting, event handlers and process managers. Note the previous approach to defining and starting may still be used, so this is _not_ a breaking change.

---

## v0.11.0

### Enhancements

- Shutdown idle aggregate processes ([#43](https://github.com/commanded/commanded/issues/43)).

---

## v0.10.0

### Enhancements

- Extract event store integration to a behaviour (`Commanded.EventStore`). This defines the contract to be implemented by an event store adapter. It allows additional event store databases to be used with Commanded.

  By default, a `GenServer` in-memory event store adapter is used. This should **only be used for testing** as there is no persistence.

  The existing PostgreSQL-based [eventstore](https://github.com/commanded/eventstore) integration has been extracted as a separate package ([commanded_eventstore_adapter](https://github.com/commanded/commanded-eventstore-adapter)). There is also a new adapter for Greg Young's Event Store using the Extreme library ([commanded_extreme_adapter](https://github.com/commanded/commanded-extreme-adapter)).

  You must install the required event store adapter package and update your environment configuration to specify the `:event_store_adapter` module. See the [README](https://github.com/commanded/commanded/blob/master/README.md) for details.

---

## v0.9.0

### Enhancements

- Stream events from event store when rebuilding aggregate state.

---

## v0.8.5

### Enhancements

- Upgrade to Elixir 1.4 and remove compiler warnings.

## v0.8.4

### Enhancements

- Event handler and process manager subscriptions should be created from a given stream position ([#14](https://github.com/commanded/commanded/issues/14)).
- Stop process manager instance after reaching its final state ([#24](https://github.com/commanded/commanded/issues/24)).

## v0.8.3

### Enhancements

- Middleware `after_failure` callback is executed even when a middleware halts execution.

## v0.8.2

### Bug fixes

- JsonSerializer should ensure event type atom exists when deserializing ([#28](https://github.com/commanded/commanded/issues/28)).

## v0.8.1

### Enhancements

- Command handlers should be optional by default ([#30](https://github.com/commanded/commanded/issues/30)).

## v0.8.0

### Enhancements

- Simplify aggregates and process managers ([#31](https://github.com/commanded/commanded/issues/31)).

---

## v0.7.1

### Bug fixes

- Restarting aggregate process should load all events from its stream in batches. The Event Store read stream default limit is 1,000 events.

## v0.7.0

### Enhancements

- Command handling middleware allows a command router to define middleware modules that are executed before, and after success or failure of each command dispatch ([#12](https://github.com/commanded/commanded/issues/12)).

---

## v0.6.3

### Enhancements

- Process manager instance processes event non-blocking to prevent timeout during event processing and any command dispatching. It persists last seen event id to ensure events are handled only once.

## v0.6.2

### Enhancements

- Command dispatch timeout. Allow a `timeout` value to be configured during command registration or dispatch. This overrides the default timeout of 5 seconds. The same as the default `GenServer` call timeout.

### Bug fixes

- Fix pending aggregates restarts: supervisor restarts aggregate process but it cannot accept commands ([#22](https://github.com/commanded/commanded/pull/22)).

## v0.6.1

### Enhancements

- Upgrade `eventstore` mix dependency to v0.6.0 to use support for recorded events created_at as `NaiveDateTime`.

## v0.6.0

### Enhancements

- Confirm receipt of events in event handler and process manager router ([#19](https://github.com/commanded/commanded/pull/19)).
- Convert keys to atoms when decoding JSON using Poison decoder.
- Prefix process manager instance snapshot uuid with process manager name.
- Multi command dispatch registration in router ([#16](https://github.com/commanded/commanded/issues/16)).

---

## v0.5.0

### Enhancements

- Include event metadata as second argument to event handlers. An event handler must now implement the `Commanded.Event.Handler` behaviour consisting of a single `handle_event/2` function.

---

## v0.4.0

### Enhancements

- Macro to assist with building process managers ([README](https://github.com/commanded/commanded/tree/feature/process-manager-macro#process-managers)).

---

## v0.3.1

### Enhancements

- Include unit test event assertion function: `assert_receive_event/2` ([#13](https://github.com/commanded/commanded/pull/13)).
- Include top level application in mix config.

## v0.3.0

### Enhancements

- Don't persist an aggregate's pending events when executing a command returns an error ([#10](https://github.com/commanded/commanded/pull/10)).

### Bug fixes

- Ensure an aggregate's pending events are persisted in the order they were applied.

---

## v0.2.1

### Enhancements

- Support integer, atom or strings as an aggregate UUID ([#7](https://github.com/commanded/commanded/pull/7)).

## v0.1.0

Initial release.
