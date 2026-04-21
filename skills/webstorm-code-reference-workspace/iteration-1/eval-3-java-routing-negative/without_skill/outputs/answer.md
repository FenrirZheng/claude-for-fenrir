# Callers of `UserService.create` (or similar) in `camhr/`

## Tools used

- **`fdfind`** to locate Java files matching `*UserService*.java` (per global rule: prefer `fdfind` over `find`).
- **`rg` (ripgrep) via the Grep tool** to search file contents (per global rule: prefer `rg` over `grep`). I searched for:
  - Class/interface declarations: `class UserService`, `interface UserService`
  - Symbol usages of the bare token `UserService`
  - Method-call patterns `UserService.create` / `userService.create` / `BgUserService.create` / `bgUserService.create`
  - A broader fallback regex for any user-named service with a creation-style method: `[uU]ser[A-Za-z]*Service\.(create|add|insert|save|register)\w*\(`

I deliberately did **not** use the WebStorm/IntelliJ MCP semantic tools here — this is a pure read-only grep-style lookup across a Maven/Java project and `rg` is sufficient and faster for a negative-result confirmation. (If the result had been ambiguous — e.g. Spring proxy/AOP indirection, interface-vs-impl resolution, overloads — I would have escalated to the IntelliJ MCP, `mcp__idea__*`.)

## Results

**No hits.** There is no class or interface named `UserService` anywhere under `/home/fenrir/code/camhr/camhr`, and consequently no call sites of `UserService.create`.

Evidence:

- `rg '\bUserService\b' --type java` against `/home/fenrir/code/camhr/camhr` → **0 matches** (the bare symbol `UserService` does not appear even as a type reference, import, or `@Autowired` field).
- `rg 'UserService\.create|userService\.create|bgUserService\.create|BgUserService\.create' --type java` → **0 matches**.
- `fdfind -e java 'User.*Service'` returns only related-but-distinct services (none named `UserService`):
  - `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/admin/user/admin/service/BgUserService.java`
  - `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/admin/user/admin/service/impl/BgUserServiceImpl.java`
  - `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/message/service/UserMsgStatisticsService.java` (+ impl)
  - `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/user/service/UserAppDeviceService.java` (+ impl)
  - `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/user/service/UserFileService.java` (+ impl)
  - `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/user/service/UserJobStatisticsService.java` (+ impl)
  - `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/user/service/UserResumeService.java` (+ impl)
- Neither `BgUserService.java` nor `BgUserServiceImpl.java` declare any method named `create(...)`.

### "Similarly-named user-creation service method" — nearest analogues

For completeness, the closest user-creation-shaped call sites I found (none of them are named `create` and none are on a `UserService`):

- `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/admin/user/admin/controller/BgUserController.java:56` — `bgUserService.addBgUser(bgUser)` *(admin/backoffice user creation; on `BgUserService`, method is `addBgUser`, not `create`)*
- `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/user/controller/UserResumeController.java:154` — `userResumeService.addUserResume(resume)` *(creates a resume record, not a user; on `UserResumeService`)*
- `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/user/controller/UserResumeController.java:163` — `userResumeService.addAttachmentResume(user.getUserId(), file, fileNameEncode)` *(creates an attachment resume; on `UserResumeService`)*
- `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/user/service/impl/IntentionServiceImpl.java:50` — `userResumeService.addUserResume(resume)` *(same `UserResumeService#addUserResume`, called internally)*
- `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/user/controller/AppDeviceController.java:42` — `userAppDeviceService.saveAppDevice(appDevice)` *(registers a device for a user; on `UserAppDeviceService`)*
- `/home/fenrir/code/camhr/camhr/camhr-core/src/main/java/com/camhr/employer/controller/EmployerDeviceController.java:43` — `userAppDeviceService.saveAppDevice(appDevice)` *(same method, employer-side)*

These are listed only as context; they are **not** callers of `UserService.create`.

## Summary

The Spring Boot backend at `/home/fenrir/code/camhr/camhr` does **not** contain a `UserService` type, and therefore has **zero callers** of `UserService.create`. The only user-domain service that resembles the name is `BgUserService` (admin-user management), whose creation method is `addBgUser`, not `create`. The codebase consistently uses `addXxx` / `saveXxx` naming for creation-shaped service methods rather than `create`. The answer to "find all callers of `UserService.create`" is an empty set.
