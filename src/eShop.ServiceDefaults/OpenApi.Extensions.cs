using Asp.Versioning;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Scalar.AspNetCore;

namespace eShop.ServiceDefaults;

public static partial class Extensions
{
    // TEMPORARILY DISABLED FOR .NET 9 COMPATIBILITY
    // OpenAPI functionality disabled due to breaking changes between Microsoft.OpenApi 1.6.x (required by .NET 9)
    // and Microsoft.OpenApi 2.x (used by .NET 10). The core functionality (catalog, basket, ordering) works without OpenAPI.
    
    public static IApplicationBuilder UseDefaultOpenApi(this WebApplication app)
    {
        // OpenAPI disabled for .NET 9 compatibility
        return app;
    }

    public static IHostApplicationBuilder AddDefaultOpenApi(
        this IHostApplicationBuilder builder,
        IApiVersioningBuilder? apiVersioning = default)
    {
        // OpenAPI disabled for .NET 9 compatibility
        return builder;
    }
}
