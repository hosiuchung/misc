using Abp.Runtime.Caching.Redis;
using Castle.Core;
using Castle.MicroKernel;

namespace AbpDemo.AOP.Redis
{
    public class RedisExceptionInterceptorRegistrar
    {
        public static void Initialize(IKernel kernel)
        {
            kernel.ComponentRegistered += (key, handler) =>
            {
                if (typeof(AbpRedisCache).IsAssignableFrom(handler.ComponentModel.Implementation))
                    handler.ComponentModel.Interceptors.Add(
                        new InterceptorReference(typeof(RedisExceptionInterceptor)));
            };
        }
    }
}
