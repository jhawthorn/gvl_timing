# frozen_string_literal: true

require "mkmf"

# Makes all symbols private by default to avoid unintended conflict
# with other gems. To explicitly export symbols you can use RUBY_FUNC_EXPORTED
# selectively, or entirely remove this flag.
append_cflags("-fvisibility=hidden")

have_header("ruby/thread.h")
have_struct_member("rb_internal_thread_event_data_t", "thread", ["ruby/thread.h"])

create_makefile("gvl_timing/gvl_timing")
