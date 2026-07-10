set flatten_modules {premux mux decoder encoder priencoder privector priarb rca sext shf flop dff dffr}

set cells [get_cells -hier -filter {CLASS == cell && IS_PRIMITIVE == 0}]
foreach module $flatten_modules {
    set cells [filter $cells "ORIG_REF_NAME != $module"]
}

set_property KEEP_HIERARCHY TRUE $cells
