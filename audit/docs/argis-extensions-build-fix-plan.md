# argis-extensions Build Fix Plan

**Date:** 2026-09-13
**Issue:** Build broken due to GraphQL interface mismatches
**Priority:** HIGH (second priority after HexaKit)

---

## Compilation Errors Summary

### 1. GraphQL Generated Code Version Mismatch
**Location:** `api/graphql/gen/generated.go`
**Error:** `field.Deferrable undefined (type graphql.CollectedField has no field or method Deferrable)`
**Count:** 10+ occurrences
**Root Cause:** Generated code uses `Deferrable` field that doesn't exist in current gqlgen version
**Fix:** Regenerate GraphQL code using `go run github.com/99designs/gqlgen generate`

### 2. Plugin Schema Mismatches
**Location:** `plugins/argis/adapter.go`, `plugins/argis/plugin.go`
**Errors:**
- `undefined: schemas.BifrostContext`
- `cr.Provider undefined (type *schemas.ChatRequest has no field or method Provider)`
- `req.RequestType undefined (type *schemas.BifrostRequest has no field or method RequestType)`
- `undefined: schemas.ChatCompletionStreamRequest`
- `cr.Params.MaxCompletionTokens undefined (type *schemas.ChatParams has no field or method MaxCompletionTokens)`
**Root Cause:** Plugin code references fields/methods that don't exist in current schema
**Fix:** Update plugin code to match current schema definitions

### 3. Content Safety Plugin Errors
**Location:** `plugins/contentsafety/plugin.go`
**Errors:**
- `unknown field Error in struct literal of type schemas.BifrostError`
- `msg.Content undefined (type rune has no field or method Content)`
- `choice.ChatNonStreamResponseChoice undefined (type schemas.ChatResponseChoice has no field or method ChatNonStreamResponseChoice)`
**Root Cause:** Plugin code references fields that don't exist in current schema
**Fix:** Update plugin code to match current schema definitions

### 4. Context Folding Plugin Errors
**Location:** `plugins/contextfolding/folding.go`
**Errors:**
- `invalid operation: msg.Content != nil (mismatched types string and untyped nil)`
- `msg.Content.ContentStr undefined (type string has no field or method ContentStr)`
- `cannot use &schemas.ChatMessageContent{…} (value of type *schemas.ChatMessageContent) as string value in struct literal`
**Root Cause:** Type mismatches between string and ChatMessageContent
**Fix:** Update plugin code to handle correct types

### 5. Tool Router Plugin Errors
**Location:** `plugins/toolrouter/routing.go`
**Error:** `cannot use &schemas.ChatParameters{} (value of type *schemas.ChatParameters) as *schemas.ChatParams value in assignment`
**Root Cause:** Type mismatch between ChatParameters and ChatParams
**Fix:** Update plugin code to use correct type

---

## Fix Plan

### Phase 1: Regenerate GraphQL Code (1-2 hours)
1. Install gqlgen: `go install github.com/99designs/gqlgen@latest`
2. Run code generation: `cd api/graphql && go run github.com/99designs/gqlgen generate`
3. Verify generated code compiles
4. Commit regenerated code

### Phase 2: Fix Plugin Schema Mismatches (2-4 hours)
1. Review current schema definitions in `api/graphql/schema/*.graphql`
2. Update plugin code to match current schema
3. Fix type mismatches
4. Test each plugin individually

### Phase 3: Fix Remaining Compilation Errors (1-2 hours)
1. Fix any remaining compilation errors
2. Run full build: `go build ./...`
3. Run tests: `go test ./...`
4. Verify all tests pass

### Phase 4: Create PR and Review (1 hour)
1. Create PR with all fixes
2. Add comprehensive description
3. Request review
4. Merge after approval

---

## Estimated Total Time: 5-9 hours

---

## Risk Assessment

**Risk Level:** MEDIUM
- Changes are focused on build fixes, not feature work
- Regenerating GraphQL code is a standard operation
- Plugin fixes are straightforward schema updates

**Mitigation:**
- Test each change individually
- Verify compilation after each phase
- Create comprehensive PR description

---

## Success Criteria

1. `go build ./...` succeeds without errors
2. `go test ./...` passes
3. CI pipeline passes
4. All plugins compile and work correctly
5. GraphQL API works as expected

---

## Notes

- This is the second priority after HexaKit (which is now fixed)
- The build has been broken for some time (4 months since last commit)
- The issues are straightforward to fix but require careful attention to schema details
- Consider adding CI checks to prevent this from happening again
