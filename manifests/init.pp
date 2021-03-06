# Copyright 2011 MaestroDev
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class continuum(
    $version = "1.4.0",
    $user = "continuum",
    $group = "continuum",
    $user_home = undef,
    $download_mirror = "http://archive.apache.org/dist",
    $download_maven_repo = {
      #url => "http://repo1.maven.org/maven2",
      #username => "",
      #password => "",
    },
    $shared_secret_password = undef) {
}
