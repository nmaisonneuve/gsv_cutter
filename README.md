# GsvCutter





##CONTEXT ##

- We have the cadastre (OSM) - a large set of buildings represented by multi_polygons
- a large set of Panorama represented by geolocation + spherical images + point of observation (direction angle of the car = center of the image).

## GOAL ##
The goal is to have for
- For a given panorama, finding all the visible/observable buildings with their associated angle of observation.
OR
- for a given visible building, finding all the panorama images where it can be observed with its associated angle of observation.



## Installation

Add this line to your application's Gemfile:

    gem 'gsv_cutter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gsv_cutter

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
