#!/bin/bash

chmod +a "`whoami` allow write,delete,append,file_inherit,directory_inherit" $@
chmod +a "_www allow write,delete,append,file_inherit,directory_inherit" $@

