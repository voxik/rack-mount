#include "ruby.h"

static VALUE rb_nested_set_aref(int argc, VALUE *argv, VALUE self)
{
	int i;
	VALUE r;

	for (i = 0, r = self; rb_obj_is_kind_of(r, rb_cArray) == Qfalse; i++)
		r = rb_hash_aref(r, (i < argc) ? argv[i] : Qnil);

	return r;
}

VALUE cNestedSetExt;

void Init_nested_set_ext() {
	VALUE cMount = rb_eval_string("::Rack::Mount");
	cNestedSetExt = rb_define_module_under(cMount, "NestedSetExt");
	rb_define_method(cNestedSetExt, "cfetch", rb_nested_set_aref, -1);
}
