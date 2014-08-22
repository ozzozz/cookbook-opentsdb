name             'opentsdb'
maintainer       'ozzozz'
maintainer_email 'cookbooks@kn.ozz.in'
license          'All rights reserved'
description      'Installs/Configures opentsdb'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.5'

supports 'ubuntu', '= 10.04'
supports 'ubuntu', '= 12.04'
supports 'ubuntu', '= 14.04'

depends 'apt',  '~> 2.3.0'
depends 'java', '~> 1.21.0'
