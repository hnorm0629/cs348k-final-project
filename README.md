# CS348K Final Project

_DyDef: A Visualization Tool for Dynamic Deformations on Shell Objects_

I am going to develop a GUI that allows users to visualize dynamic deformations on a halfpipe shell object. The project will build on existing computational models for shell deformation and will include features for both simulation analysis and visualization. I will use DeformFX—a software library for nonlinear finite element simulation—as the foundation of this application. This GUI will primarily serve as a tool for better understanding the physical behavior of this halfpipe shell structure as it deforms.

**Disclaimer: I did not create halfpipe; it was kindly provided by a third party. I will be building atop the existing infrastructure to improve its dynamic deformation GUI. All commits past the initial commit are my own work. All code contained within the initial commit is not.**

# halfpipe

Simulate and render a half cylinder with a point force applied at the
center-end.

Tested on a 2020 M1 Mac Mini running MacOS 12.1.
                                                                              
Depends on the AdaptableFiniteElementKit framework available at:

https://github.com/MECV/AdaptableFiniteElementKit/releases

After unzipping AdaptableFiniteElementKit.tar.gz add the framework
to the project as follows.

1: Select the HalfPipe top-level project in the left pane.

2: Select the HalfPipe target under Targets.

3: Select the General tab.

4: Navigate down to Frameworks, Libraries, and Embedded Content.

5: Select the + -> Add Other... -> Add Files

6: Navigate to where you unzipped AdaptableFiniteElementKit.tar.gz and
   further navigate to AdaptableFiniteElementKit.dst/Library/Frameworks
   and select the folder AdaptableFiniteElementKit.framework and click
   Open.
   
7: Now select the Build Settings tab.

8: Locate the Framework Search Paths setting under the Search Paths
   section.  It may help to search for the term Framework Search Paths
   in the search box on the right.
   
9: Double click the setting field to the right of Framework Search Paths
   and add the path to the frameworks directory above, for example,
   /My/Path/To/AdaptableFiniteElementKit.dst/Library/Frameworks.
   
10:Click the Play button on the top left, or Cmd-R to run the app.
