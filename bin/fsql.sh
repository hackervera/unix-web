#!/bin/bash
fsql "select * from . where size > $MINSIZE"