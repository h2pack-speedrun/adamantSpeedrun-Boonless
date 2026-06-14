local module = {}

function module.buildPatchPlan(patches, _, runtime, plan)
    for _, patch in ipairs(patches) do
        if runtime.data.read(patch.key) and patch.fn then
            patch.fn(plan)
        end
    end
end

function module.registerHooks(moduleRef, hooks)
    for _, fn in ipairs(hooks) do
        fn(moduleRef)
    end
end

function module.attach(moduleRef, patches, hooks)
    moduleRef.mutation.patch(function(...)
        return module.buildPatchPlan(patches, ...)
    end)
    module.registerHooks(moduleRef, hooks)
end

return module
