/**
 * Environment variable configuration source adapter.
 *
 * Implements ConfigSource port for environment variables.
 */

import { ConfigSource } from '../ports/config-source';
import { ConfigEntry, ConfigValue, ConfigValueSchema } from '../domain/config';

/**
 * Environment variable config source.
 *
 * Reads configuration from process.env.
 */
export class EnvConfigSource implements ConfigSource {
  readonly name = 'env';
  private readonly prefix: string;

  constructor(prefix = 'APP_') {
    this.prefix = prefix;
  }

  async load(): Promise<ConfigEntry[]> {
    const entries: ConfigEntry[] = [];

    for (const [key, value] of Object.entries(process.env)) {
      if (key.startsWith(this.prefix) && value !== undefined) {
        entries.push({
          key: this.stripPrefix(key),
          value: this.parseValue(value),
          source: this.name,
          timestamp: Date.now(),
        });
      }
    }

    return entries;
  }

  async get(key: string): Promise<ConfigValue | undefined> {
    const fullKey = this.prefix + key.toUpperCase();
    const value = process.env[fullKey];
    if (value === undefined) return undefined;
    return this.parseValue(value);
  }

  async set(key: string, value: ConfigValue): Promise<void> {
    // Environment variables are read-only in most contexts
    throw new Error('Environment variables are read-only');
  }

  isWritable(): boolean {
    return false;
  }

  private stripPrefix(key: string): string {
    return key.slice(this.prefix.length).toLowerCase();
  }

  private parseValue(value: string): ConfigValue {
    // Try to parse as JSON for complex types
    try {
      const parsed = JSON.parse(value);
      // JSON.parse("null") returns JS null, which is not a valid ConfigValue.
      // Treat the literal string "null" as the string "null".
      if (parsed === null) {
        return 'null' as ConfigValue;
      }
      if (Array.isArray(parsed)) {
        // ConfigValueSchema only allows z.array(z.string()); filter out
        // any non-string elements so the return value stays type-safe.
        return parsed.filter(
          (el: unknown): el is string => typeof el === 'string'
        ) as ConfigValue;
      }
      if (typeof parsed === 'object') {
        // ConfigValueSchema only allows z.record(z.string(), z.string());
        // drop any key whose value is not a string.
        const out: Record<string, string> = {};
        for (const [k, v] of Object.entries(parsed)) {
          if (typeof v === 'string') out[k] = v;
        }
        return out as ConfigValue;
      }
    } catch {
      // Not JSON, return as string
    }

    // Try boolean
    if (value.toLowerCase() === 'true') return true;
    if (value.toLowerCase() === 'false') return false;

    // Try number
    if (!isNaN(Number(value))) return Number(value);

    // Return as string
    return value;
  }
}
