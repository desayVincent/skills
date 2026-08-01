> Disclosed reference from write-legible-c `c-standard` (7etsuo, MIT).
> Load only on the branch named in [write-legible-c-SKILL.md](write-legible-c-SKILL.md).
> Normative rules remain in [c-standard.md](c-standard.md) sections 1–14.

# Skeleton (greenfield module pattern)

```c
/* sensor.c: owns polling and conversion for the temperature sensor. */

#include <stdint.h>

#include "bus.h"
#include "sensor.h"

enum {
    SENSOR_POLL_INTERVAL_MS = 250,
    SENSOR_RAW_MAX          = 4095,
    SENSOR_SCALE_MILLIDEG   = 62
};

/* Propagates any non-OK status to the caller. Permitted only in
 * functions that acquire nothing. Sole macro allowed to return. */
#define SENSOR_TRY(expr)                            \
    do {                                            \
        sensor_status_t sensor_try_s_ = (expr);     \
        if (sensor_try_s_ != SENSOR_OK)             \
            return sensor_try_s_;                   \
    } while (0)

struct sensor {
    bus_t   *bus;       /* borrowed, never owned */
    int32_t  last_millideg;
};

/* Rejects a NULL sensor or output pointer. Fails with SENSOR_ERR_ARG. */
static sensor_status_t sensor_validate_poll_args(const sensor_t *s,
                                                 const int32_t *out_millideg);

/* Adapter over bus_read_u16. Fails with SENSOR_ERR_BUS. */
static sensor_status_t sensor_read_raw(sensor_t *s, uint16_t *out_raw);

/* Rejects raw samples above hardware range. Fails with SENSOR_ERR_RANGE. */
static sensor_status_t sensor_validate_raw(uint16_t raw);

/* Caches the converted sample on the sensor. Returns it in millidegrees. */
static int32_t sensor_record(sensor_t *s, uint16_t raw);

/* Converts a raw sample to millidegrees. Pure. */
static int32_t sensor_convert(uint16_t raw);

sensor_status_t sensor_poll(sensor_t *s, int32_t *out_millideg)
{
    SENSOR_TRY(sensor_validate_poll_args(s, out_millideg));

    uint16_t raw = 0;
    SENSOR_TRY(sensor_read_raw(s, &raw));
    SENSOR_TRY(sensor_validate_raw(raw));

    *out_millideg = sensor_record(s, raw);
    return SENSOR_OK;
}

static sensor_status_t sensor_validate_poll_args(const sensor_t *s,
                                                 const int32_t *out_millideg)
{
    if (s == NULL)
        return SENSOR_ERR_ARG;
    if (out_millideg == NULL)
        return SENSOR_ERR_ARG;
    return SENSOR_OK;
}

static sensor_status_t sensor_read_raw(sensor_t *s, uint16_t *out_raw)
{
    bus_status_t status = bus_read_u16(s->bus, SENSOR_REG_DATA, out_raw);
    if (status != BUS_OK)
        return SENSOR_ERR_BUS;
    return SENSOR_OK;
}

static sensor_status_t sensor_validate_raw(uint16_t raw)
{
    if (raw > SENSOR_RAW_MAX)
        return SENSOR_ERR_RANGE;
    return SENSOR_OK;
}

static int32_t sensor_record(sensor_t *s, uint16_t raw)
{
    s->last_millideg = sensor_convert(raw);
    return s->last_millideg;
}

static int32_t sensor_convert(uint16_t raw)
{
    return (int32_t)raw * SENSOR_SCALE_MILLIDEG;
}
```

Every rule above appears in this skeleton. `sensor_poll` is now six lines of
pure plan with zero propagation ceremony. Every leaf holds one piece of
logic, the adapter owns the only foreign call, and every error value has
exactly one producing line, so any failure greps to its cause in one step.
The file still teaches its complete vocabulary in the first screen.

