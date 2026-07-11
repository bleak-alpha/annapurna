package com.annapurna.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.CacheManager;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

@Configuration
public class CacheConfig {

    @Value("${app.cache.expiry-hours}")
    private int cacheExpiry;

    public CacheManager cacheManager(){

        CaffeineCacheManager maneger = new CaffeineCacheManager(
                "activeMenuCache"
        );

        maneger.setCaffeine(
                Caffeine.newBuilder()
                        .maximumSize(1000)
                        .expireAfterWrite( cacheExpiry,
                                TimeUnit.HOURS));

        return maneger;

    }

}
