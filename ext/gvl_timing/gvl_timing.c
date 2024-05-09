#include "gvl_timing.h"

static VALUE rb_mGVLTiming;

RUBY_FUNC_EXPORTED void
Init_gvl_timing(void)
{
    rb_mGVLTiming = rb_define_module("GVLTiming");
}
