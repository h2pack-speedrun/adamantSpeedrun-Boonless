local module = {}

function module.registerHooks(moduleRef, hooks)
    for _, fn in ipairs(hooks) do
        fn(moduleRef)
    end
end

function module.attach(moduleRef, hooks)
    module.registerHooks(moduleRef, hooks)
end

return module
