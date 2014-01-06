# GsvCutter





##CONTEXT ##

- We have the cadastre (OSM) - a large set of buildings represented by multi_polygons
- a large set of Panorama represented by geolocation + spherical images + point of observation (direction angle of the car = center of the image).

## GOAL ##
The goal is to have for
- For a given panorama, finding all the visible/observable buildings with their associated angle of observation.
OR
- for a given visible building, finding all the panorama images where it can be observed with its associated angle of observation.


## installation

		$ bundle install

## usage

List of functions / Help

    $ rake -T 

And then execute on of the task in the namespace 'rays':

    $ rake rays:*

