#include "gvl_timing.h"
#include "ruby/thread.h"

static VALUE rb_mGVLTiming;
static VALUE rb_cTimer;

static const uint64_t nanoseconds_per_second = 1000000000;

static uint64_t clock_gettime_ns(clockid_t clock_id) {
    struct timespec ts;
    clock_gettime(clock_id, &ts);
    return ts.tv_sec * nanoseconds_per_second + ts.tv_nsec;
}

enum ruby_gvl_state {
    GVL_STATE_RUNNING = 0,
    GVL_STATE_STALLED = 1,
    GVL_STATE_IDLE = 2,
};

struct gvl_timer {
    uint64_t timings[3];

    uint64_t monotonic_start;
    uint64_t monotonic_stop;
    uint64_t cputime_start;
    uint64_t cputime_stop;

    uint64_t releases_count;

    uint64_t prev_timestamp;
    enum ruby_gvl_state prev_state;
    VALUE thread;
    rb_internal_thread_event_hook_t *event_hook;

    bool running;
};

void record_timing(struct gvl_timer *timer, enum ruby_gvl_state new_state) {
    uint64_t timestamp = clock_gettime_ns(CLOCK_MONOTONIC);

    timer->timings[timer->prev_state] += (timestamp - timer->prev_timestamp);
    timer->prev_timestamp = timestamp;
    timer->prev_state = new_state;

    if (new_state == GVL_STATE_IDLE) {
        timer->releases_count++;
    }

}

void internal_thread_event_cb(rb_event_flag_t event, const rb_internal_thread_event_data_t *event_data, void *data) {
    struct gvl_timer *timer = data;

    if (!ruby_native_thread_p()) return;
    VALUE thread = rb_thread_current();
//#if HAVE_RB_INTERNAL_THREAD_EVENT_DATA_T_THREAD
//#else
//#endif
    if (thread != timer->thread) {
        return;
    }

    enum ruby_gvl_state new_state;
    switch (event) {
      case RUBY_INTERNAL_THREAD_EVENT_READY:
        new_state = GVL_STATE_STALLED;
        break;
      case RUBY_INTERNAL_THREAD_EVENT_RESUMED:
        new_state = GVL_STATE_RUNNING;
        break;
      case RUBY_INTERNAL_THREAD_EVENT_SUSPENDED:
        new_state = GVL_STATE_IDLE;
        break;
      default:
        return;
    }

    record_timing(timer, new_state);
}

static const rb_data_type_t gvl_timer_type = {
    .wrap_struct_name = "gvl_timer",
    .function = {
        //.dmemsize = rb_collector_memsize,
        //.dmark = collector_mark,
        //.dfree = collector_free,
    },
};

VALUE gvl_timer_alloc(VALUE klass) {
    struct gvl_timer *timer;
    VALUE obj = TypedData_Make_Struct(klass, struct gvl_timer, &gvl_timer_type, timer);
    return obj;
}

struct gvl_timer *get_timer(VALUE obj) {
    struct gvl_timer *timer;
    TypedData_Get_Struct(obj, struct gvl_timer, &gvl_timer_type, timer);
    return timer;
}

VALUE gvl_timer_start(VALUE obj) {
    struct gvl_timer *timer = get_timer(obj);
    timer->monotonic_start = clock_gettime_ns(CLOCK_MONOTONIC);
    timer->cputime_start   = clock_gettime_ns(CLOCK_THREAD_CPUTIME_ID);

    timer->thread = rb_thread_current();
    timer->running = true;
    timer->event_hook = rb_internal_thread_add_event_hook(internal_thread_event_cb, RUBY_INTERNAL_THREAD_EVENT_MASK, timer);

    timer->prev_state = GVL_STATE_RUNNING;
    timer->prev_timestamp = clock_gettime_ns(CLOCK_MONOTONIC);

    return obj;
}

VALUE gvl_timer_stop(VALUE obj) {
    struct gvl_timer *timer = get_timer(obj);

    // Record last interval
    record_timing(timer, GVL_STATE_RUNNING);

    rb_internal_thread_remove_event_hook(timer->event_hook);

    timer->monotonic_stop = clock_gettime_ns(CLOCK_MONOTONIC);
    timer->cputime_stop   = clock_gettime_ns(CLOCK_THREAD_CPUTIME_ID);
    timer->running = false;
    return obj;
}

VALUE gvl_timer_monotonic_start(VALUE obj) {
    return ULL2NUM(get_timer(obj)->monotonic_start);
}

VALUE gvl_timer_monotonic_stop(VALUE obj) {
    return ULL2NUM(get_timer(obj)->monotonic_stop);
}

VALUE gvl_timer_cputime_start(VALUE obj) {
    return ULL2NUM(get_timer(obj)->cputime_start);
}

VALUE gvl_timer_cputime_stop(VALUE obj) {
    return ULL2NUM(get_timer(obj)->cputime_stop);
}

VALUE gvl_timer_running_duration(VALUE obj) {
    return ULL2NUM(get_timer(obj)->timings[GVL_STATE_RUNNING]);
}

VALUE gvl_timer_stalled_duration(VALUE obj) {
    return ULL2NUM(get_timer(obj)->timings[GVL_STATE_STALLED]);
}

VALUE gvl_timer_idle_duration(VALUE obj) {
    return ULL2NUM(get_timer(obj)->timings[GVL_STATE_IDLE]);
}

VALUE gvl_timer_releases_count(VALUE obj) {
    return ULL2NUM(get_timer(obj)->releases_count);
}

RUBY_FUNC_EXPORTED void
Init_gvl_timing(void)
{
    rb_mGVLTiming = rb_define_module("GVLTiming");
    rb_cTimer = rb_define_class_under(rb_mGVLTiming, "Timer", rb_cObject);
    rb_define_alloc_func(rb_cTimer, gvl_timer_alloc);
    rb_define_method(rb_cTimer, "start", gvl_timer_start, 0);
    rb_define_method(rb_cTimer, "stop", gvl_timer_stop, 0);

    rb_define_method(rb_cTimer, "monotonic_start_ns", gvl_timer_monotonic_start, 0);
    rb_define_method(rb_cTimer, "monotonic_stop_ns", gvl_timer_monotonic_stop, 0);
    rb_define_method(rb_cTimer, "cputime_start_ns", gvl_timer_cputime_start, 0);
    rb_define_method(rb_cTimer, "cputime_stop_ns", gvl_timer_cputime_stop, 0);

    rb_define_method(rb_cTimer, "running_duration_ns", gvl_timer_running_duration, 0);
    rb_define_method(rb_cTimer, "stalled_duration_ns", gvl_timer_stalled_duration, 0);
    rb_define_method(rb_cTimer, "idle_duration_ns", gvl_timer_idle_duration, 0);

    rb_define_method(rb_cTimer, "releases_count", gvl_timer_releases_count, 0);
}
