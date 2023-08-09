# Installing custom R packages

Installing ```R``` packages for public use (and future ```RPlus``` modules can be requested via the helpdesk).
But it is still possible to install an ```R``` package in a ```tmp``` group folder yourself and optionally share it with your colleagues.

## Create location for custom R packages and prepend that to the search path for R packages

First you will need to choose a location where you want to install your custom ```R``` packages.
This path needs to be added to the ```${R_LIBS_USER}``` environment variable in your ```${HOME}/.Renviron``` config file.

###### 1. Create a ${HOME}/.Renviron file

```bash
touch ${HOME}/.Renviron
```

This will create a ```.Renviron``` file in your home dir if you did not already have one.
If the file already exists the touch command will only update the last modification time stamp of the file and leave the content unchanged.

###### 2. Add ${R_LIBS_USER} to ${HOME}/.Renviron file

E.g. if the path you chose for your custom R package is in the ```tmp09``` folder of the group named ```my-favorite-group```,
then add something like this to your ```~/.Renviron``` file:

```bash
R_LIBS_USER=/groups/my-favorite-group/tmp09/R-packages/%p-library/%v
```

Note the `%p` and `%v` expand to the _platform_ and _version_ of the used R module, respectively.

###### 3. Start R and make sure the ${R_LIBS_USER} path exists

Load either a _bare_ ```R``` or load ```RPlus```, which is a bundle of lots of ```R``` packages already pre-installed on {{ slurm_cluster_name | capitalize }}.

```bash
module load RPlus
R
```

Next use the ```.libPaths()``` function in ```R``` to check the value(s) for the paths where ```R``` will search for extra packages.
By default new ```R``` packages will be installed in the first folder reported by ```.libPaths()```

```R
R> .libPaths()
[1] "/groups/my-favorite-group/tmp09/R-packages/x86_64-pc-linux-gnu-library/4.2"
[2] "/apps/software/R/4.2.2-foss-2022a-bare/lib64/R/library"
```

If the ```.libPaths()``` function does not list your folder for custom R packages (first),
but for example only the library folder for the loaded ```R``` version itself like this

```R
R> .libPaths()
[1] "/apps/software/R/4.2.2-foss-2022a-bare/lib64/R/library"
```

Then this most likely means that the path specified in ```${R_LIBS_USER}``` does not exist yet;
In that case create the path, quit ```R``` and restart ```R``` using
```R
R> # Check the value of ${R_LIBS_USER}
R> Sys.getenv('R_LIBS_USER')
R> # Create the ${R_LIBS_USER} path recursively
R> dir.create(Sys.getenv('R_LIBS_USER'), recursive = TRUE)
R> # Quit R
R> q()
```
```bash
# Start R again
R
```
```R
R> # Use .libPaths again to make sure your ${R_LIBS_USER} path is the first path listed
R> .libPaths()
[1] "/groups/my-favorite-group/tmp09/R-packages/x86_64-pc-linux-gnu-library/4.2"
[2] "/apps/software/R/4.2.2-foss-2022a-bare/lib64/R/library" 
```

## Install custom R packages

With your custom folder for ```R``` packages present on the file system and listed as the first item by the ```.libPaths``` function,
you can now install packages. Below are examples of installing packages from different sources.

###### A. Install R package from the Comprehensive R Archive Network (CRAN) repository

Load and start R.

```bash
module load RPlus
R
```

Use the [```install.packages()``` function](https://cran.r-project.org/doc/manuals/r-release/R-admin.html#Installing-packages)
to install packages from [_CRAN_](https://cran.r-project.org/).  
E.g. to install a package named ```packageName```:

```R
R> install.packages('packageName')
```

#### B. Install R package from the BioConductor repository

Load and start R.

```bash
module load RPlus
R
```

_BioConductor_ has its own ```R``` package to manage package installations.
It is named _BiocManager_ and can be installed from _CRAN_.  
Install _BiocManager_ in ```R``` if it is not already installed: 

```R
R> if (!require("BiocManager", quietly = TRUE))
       install.packages("BiocManager")
```

Next, use _BiocManager_ to install _BioConductor_ packages. E.g.:

```R
R> BiocManager::install(c('myFavoritePackage', 'packageAlsoNeeded'))
```


#### C. Install R package from an archive file without (CRAN) repository

If the (version of the) ```R``` package you need is not available from _CRAN_ nor from _BioConductor_ nor from another ```R``` _repository_,
but you do have the source code of the package in a compressed archive file, then you can try to install that using the ```R CMD INSTALL``` command.
Note that this is sub optimal; when the code you need is available from a curated repo like _CRAN_ or _BioConductor_, use those repos instead.
In this example, we use _abctools_ version _1.1.4_ (and it was downloaded from CRAN, but it could have been fetched from another repo/source).

Since we know the URL, the command `wget` can be used to download the ```*.tar.gz``` archive.
You can also use for example ```rsync``` to copy the compressed archive to {{ slurm_cluster_name | capitalize }}
if you have the file on your local machine.

```wget https://cran.r-project.org/src/contrib/abctools_1.1.4.tar.gz```

Next, we need to load R (but do not start R yet)

```bash
module load RPlus
```

Run the command below to install the package from the compressed archive file.

```bash
R CMD INSTALL path/to/your/uploaded/abctools_1.1.4.tar.gz
```

#### D. Install R package from a GitHub repository

Load and start R.

```bash
module load RPlus
R
```

You can use the ```remotes::install_github``` command from the ```remotes``` package to install other packages from a GitHub repository.
If not already present the ```remotes``` package must be installed from _CRAN_ first.
In the example below we will install the package _methylCIPHER_ from a GitHub repo.

When no version is specified, the ```remotes::install_github``` command will install the latest commit from whatever the main branch is.
*WARNING*: this may be unstable, unreleased, untested code. In order to install the latest *released* version use ```ref = github_release()```.
You can also specify a specific version number; see the [documentation for ```remotes::install_github```](https://remotes.r-lib.org/)

```R
R> install.packages('remotes')
R> library('remotes')
R> remotes::install_github('MorganLevineLab/methylCIPHER', ref = github_release())
```

