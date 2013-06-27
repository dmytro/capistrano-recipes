

Assets Precompile Tasks
======================


There are tree different assets precompile tasks included in these recipes. You should pick one of them which suits you most:

* `assets_precompile.rb` - 'plain' one. Simply run assets:precompile rake remotely on deployment server. This can 
* `assets_precompile_conditional.rb` - same as above, but tries to detect which assets are changed and only complies those. It needs a bit of fixing, since on the first run it fails trying to compare with non-existing directory.
* `assets_precompile_local.rb`
    quote: This task compiles assets on the dev system and then pushes them up to the server. This is desirable in some situations. When deploying to a t1.micro instance, precompiling the assets on the server blows the CPU burst window and makes the server unresponsive for a long period of time. Precompiling assets locally also eliminates the need for installing a JavaScript runtime on the server (i.e. therubyracer)
    Task copied from https://github.com/willkoehler/docs/blob/master/rubber_v2.2.2/rubber_aws_deploy.md 

(Dmytro Kovalov)
