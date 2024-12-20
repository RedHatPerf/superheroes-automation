#!/bin/sh

###############################################################################
# Copyright 2023, IBM Corp.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

# Needed so the automation knows the service is up.
cat out

/opt/criu/criu restore --unprivileged -D ./cr --file-locks --shell-job -v4 --log-file=restore.log --skip-file-rwx-check --tcp-established 1>>out 2>>err </dev/null

exit 0
