The Unix Webserver
===================

Uses toml config file to map http routes to executables.

Example config.toml

```
"/" = "./echo.sh"
```

When you `curl host:3000?FOO=bar` it calls `echo.sh` with the `FOO=bar` environment variable. 

```
#!/bin/bash
echo This is a bash script. FOO is equal to $FOO
```

Echos `This is a bash script. FOO is equal to bar`

This works for any executable

Another example:

config.toml
```
"/time" = "date"
```

Shell output
```
$ curl localhost:3000/time
Sat May 20 05:20:49 PDT 2017
```

The idea is to have a webserver that follows the [Unix Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy)
