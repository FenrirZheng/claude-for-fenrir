# Callers of `UserService.create` (or similarly-named user-creation methods) in `camhr` (Java/Spring Boot)

## MCP selection

Per the `webstorm-code-reference` skill's **Language-based routing** table:

> | Java, Kotlin, Scala, Groovy | **IntelliJ MCP** (`mcp__idea__*`) — `intellij-code-reference` skill |

`/home/fenrir/code/camhr/camhr` is a Java/Maven Spring Boot project (confirmed: `pom.xml`, `camhr-core/src/main/java/...`). The skill explicitly routes this to the **IntelliJ MCP**, **not** WebStorm MCP.

However, when I queried the JetBrains MCP for currently-open projects, it reported:

```
Currently open projects: [{"path":"/home/fenrir/code/camhr/camhr-pc"}]
```

Only the frontend `camhr-pc` project is open in the IDE; the Java `camhr` backend is **not open**, so no live PSI index is available for it. Per the skill's Pitfalls section ("MCP unreachable ≠ project broken... fall back to tags/rg and say so once"), I fell back to textual search. `gtags`/`ctags` index was also absent (no `GTAGS` or `tags` file in the project root), so I used `rg` (via the Grep tool).

## Tools used

- `mcp__webstorm__get_project_modules` / `mcp__idea__get_project_modules` — to confirm no Java project is open in either JetBrains IDE.
- `Grep` (ripgrep) — for the actual caller search, since neither MCP nor a tags index covered the Java project.
- `Read` — to confirm line context on the interface definitions and call sites.

## Findings

**There is no class or interface named `UserService` in this codebase.** The user-domain code is split across several services; the closest user-**creation** entry points are:

| Service | Creation method | Defined at |
|---|---|---|
| `BgUserService` (admin/background users) | `addBgUser(BgUser)` | `camhr-core/src/main/java/com/camhr/admin/user/admin/service/BgUserService.java:13` |
| `SeekerService` (end-user / job seeker) | `registerSeeker(SeekerRegParam)` | `camhr-core/src/main/java/com/camhr/user/service/SeekerService.java:29` |
| `SeekerService` | `registerSeekerByMobile(SeekerMobileRegParam)` | `camhr-core/src/main/java/com/camhr/user/service/SeekerService.java:35` |

No method literally named `create(...)` exists on any `*UserService` / `SeekerService` interface.

### Caller sites

Service-level callers (i.e., code calling the service method, excluding the service's own implementation and the MyBatis mapper's same-name method):

- `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/admin/user/admin/controller/BgUserController.java:56` — `return Result.of(bgUserService.addBgUser(bgUser))` (REST endpoint that creates a background/admin user)
- `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/user/controller/UserController.java:108` — `if (seekerService.registerSeeker(seekerRegParam) < 1) {` (inside `POST /register` — seeker registration by email)
- `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/user/controller/UserController.java:138` — `if (seekerService.registerSeekerByMobile(mobileRegParam) < 1) {` (inside `POST /register/mobile` — seeker registration by mobile)

Noted but excluded from the caller list:

- `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/admin/user/admin/service/impl/BgUserServiceImpl.java:55` — `int row = bgUserMapper.addBgUser(bgUser);` — this is `BgUserServiceImpl` delegating to the MyBatis mapper of the same name; it is the implementation of `BgUserService.addBgUser`, not an external caller.
- `/home/fenrir/code/camhr/camhr/camhr-core/src/test/java/com/camhr/im/RestTemplateTest.java:63` — `public void createUser(){` — a JUnit `@Test` method that POSTs to a NetEase IM (external) endpoint; it does not call any internal `UserService` at all.

## Summary

`UserService` does not exist in the `camhr` Java project. The equivalent user-creation surface is `BgUserService.addBgUser` (admin users) and `SeekerService.registerSeeker` / `registerSeekerByMobile` (end users / job seekers). Across the whole `camhr` backend there are exactly **three** external call sites — all three are REST controllers (`BgUserController` once, `UserController` twice) wrapping the HTTP registration/creation endpoints. The MCP routing decision per the skill was IntelliJ MCP; the Java project was not open in the IDE, so the investigation fell back to `rg` (tags index also absent).
