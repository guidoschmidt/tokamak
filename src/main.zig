const std = @import("std");
const httpz = @import("httpz");

pub const config = @import("config.zig");
pub const cron = @import("cron.zig");
pub const monitor = @import("monitor.zig").monitor;

pub const Injector = @import("injector.zig").Injector;
pub const TypeId = @import("injector.zig").TypeId;
pub const Factory = @import("factory.zig").Factory;

pub const Server = @import("server.zig").Server;
pub const ServerOptions = @import("server.zig").InitOptions;
pub const ListenOptions = @import("server.zig").ListenOptions;
pub const Route = @import("route.zig").Route;
pub const Context = @import("context.zig").Context;
pub const Handler = @import("context.zig").Handler;
pub const Request = httpz.Request;
pub const Response = httpz.Response;

// Middlewares
pub const cors = @import("middleware/cors.zig").cors;
pub const logger = @import("middleware/logger.zig").logger;
pub const static = @import("middleware/static.zig");

// Shorthands
pub const send = Route.send;
pub const redirect = Route.redirect;

// TODO: remove this
/// Call the factory and provide result to all children. The factory can
/// use the current scope to resolve its own dependencies. If the resulting
/// type has a `deinit` method, it will be called at the end of the scope.
pub fn provide(comptime factory: anytype, children: []const Route) Route {
    const H = struct {
        fn handleProvide(ctx: *Context) anyerror!void {
            var child = .{try ctx.injector.call(factory, .{})};
            defer if (comptime @hasDecl(DerefType(@TypeOf(child[0])), "deinit")) {
                child[0].deinit();
            };

            try ctx.nextScoped(&child);
        }

        fn DerefType(comptime T: type) type {
            return switch (@typeInfo(T)) {
                .pointer => |p| p.child,
                else => T,
            };
        }
    };

    return .{
        .handler = H.handleProvide,
        .children = children,
    };
}

test {
    std.testing.refAllDecls(@This());
}
