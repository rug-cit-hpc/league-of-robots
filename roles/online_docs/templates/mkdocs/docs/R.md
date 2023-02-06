
# Table of Contents
1. [with CRAN](#install-r-package-from-released-binaries-with-cran)
2. [without CRAN](#install-r-package-from-released-binaries-without-cran)
3. [github repository](#install-r-package-from-github-repository)

Installing R packages for public use (and future RPlus can be requested via the helpdesk). But it is still possible to install an R package and share it with your colleagues (via the `lib=""` argument when installing packages). Below are 3 ways of installing packages but from different sources.

### Install R package from released binaries with CRAN
```
mkdir /sharedStorage/local/R_libs/
```
Apply function `install.packages` in the R console to download and install desired package. There are three required parameters for “install.packages” function. (1) Package name, "A3" in this case. (2) URL for the repository where we can obtain the package. Most R packages including “A3” are available on "http://cran.r-project.org" which is also known as CRAN. (3) Destination for the installed package, which, in this case, is the directory we just created `/sharedStorage/local/R_libs/`.
```
#first load the RPlus
module load RPlus/4.2.1-foss-2022a-v22.12.1
# start up R
R
## install package
install.packages("A3", repos="http://cran.r-project.org", lib="/sharedStorage/local/R_libs/")
```
To use the package from R, we call the function `library`. It is important to note that `library` by default only loads packages from root directory, so we have to specify location of the package whenever we try to include a package installed in our home directory as shown below.
```
## load package
library("A3", lib="/sharedStorage/local/R_libs/")
```

### Install R package from released binaries without CRAN

If the R package is not available on CRAN or you want to install an old version of packages, you can download the compressed file to your shared directory and install it. In this section, we use abctools 1.1.4 as example (and it is downloaded from CRAN, but it can be from every source).

It is helpful to create a new directory and move to this directory for R package installation.
```
mkdir /sharedStorage/local/R_libs/
cd /sharedStorage/local/R_libs/
```
Since we know the URL, the command `wget` can be used to download the .tar.gz file. You can also copy the compressed file to the directory, if you have the file on your local machine or somewhere else in server.

```wget https://cran.r-project.org/src/contrib/abctools_1.1.4.tar.gz```

Next, we need to load R. For this tutorial, we choose RPlus/4.2.1-foss-2022a-v22.12.1
```
module load RPlus/4.2.1-foss-2022a-v22.12.1
```
Run the command below to install the package to a specific directory. If we do not specify the path, installation will fail since by default the the package will be installed in root directory which you do not have access to.
```
R CMD INSTALL --library=/sharedStorage/local/R_libs/ abctools_1.1.4.tar.gz
```
Open the R console and load the package with the following command:
```
R
library("abctools", lib="/sharedStorage/local/R_libs/") 
```

### Install R package from github repository
To install packages from a github repository you should use the `remotes::install_github` command, in this example below we are installing the tool "methylCIPHER" and install it in our own library `/sharedStorage/local/R_libs/`

```
mkdir /sharedStorage/local/R_libs/ 
module load RPlus/4.2.1-foss-2022a-v22.12.1
R
remotes::install_github("MorganLevineLab/methylCIPHER", lib="~/sharedStorage/local/R_libs/")
```
If you want to use the package simply load it:
```
library("methylCIPHER", lib="/sharedStorage/local/R_libs/")
```
