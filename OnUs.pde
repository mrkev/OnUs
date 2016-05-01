/**
 * Project 4: On Mass Culture.
 * Experiment on interactive video.
 * Kevin Hernandez.
 * To work with the kinect, there are two
 * main drivers to choose from, depending
 * on your needs/purpose.
 *  - libfreenect: derived from the original,
 *    reverse-engineered driver.
 *      + Includes interface to control the motor of the kinect.
 *      + Released by the OpenKinect community.
 *  - OpenNI+SensorKinect: derived from open sourced PrimeSense
 *    code. (PrimeSense were the original developers of the
 *    hardware design and chip inside the Kinect, which they
 *    licensed to Microsoft in 2010)
 *      + Integration with PrimeSense NITE middleware for Natural
 *      User Interface applications, including skeleton tracking
 *      and motion gesture recogniton.
 *
 * For use with processing, the best option
 * seems to be interfacing with OpenNI
 * through SimpleOpenNI. This is the a wraper
 * around OpenNI+NITE for processing. For more
 * information, https://code.google.com/p/simple-openni/
 */
import SimpleOpenNI.*;
import gab.opencv.*;
import KinectProjectorToolkit.*;
import processing.video.*;

/** Define global parameters */

int WIDTH;                    // width of the screen
int HEIGH;                    // height of the screen
float next_vol = 1.0;         // volume of the video

OpenCV opencv;                // OpenCV object
SimpleOpenNI kinect;          // Kinect interface
KinectProjectorToolkit kpc;   // Projection tools.

ArrayList<ProjectedContour> projectedContours; // Contours of the users

Movie mov;                    // Currently playing movie
Movie next;                   // Next movie in the queue
int next_mov   = 240;         // Frames to next move (roughly 8 secs).
int TOTAL_MOVS = 16;          // Total number of movie files.

// Font object. Originally was used
// for a feature I strayed away from
// (my original idea was quite text
// heavy). Now used to draw the
// frame rate when debugging.
PFont inside_text_font;


// The following paramenters are
// for debugging, and weren't used
// during the presentation
int SIZE_JOINTS = 20;
PVector[] joints = new PVector[15];


// The following paraments were
// used at some point, but are now
// not needed
String font_family  = "Courier";
float  font_size    = 32.0;
float  font_leading = font_size * 1.6/2.0;
int    font_color   = #FFFFFF;

PImage img;
PImage i_face;
PImage i_heart;

PGraphics lCont;
PGraphics lText;

String text_to_me = "Hello\nDonec ullamcorper nulla \nnon metus auctor fringilla. \nDonec id elit non mi porta gravida \nat eget metus. Praesent commodo cursus magna, \nvel scelerisque nisl consectetur et. \nMaecenas sed diam eget risus varius blandit \nsit amet non magna. Nullam quis \nrisus eget urna mollis ornare vel eu leo. Hello\nDonec ullamcorper nulla \nnon metus auctor fringilla. \nDonec id elit non mi porta gravida \nat eget metus. Praesent commodo cursus magna, \nvel scelerisque nisl consectetur et. \nMaecenas sed diam eget risus varius blandit \nsit amet non magna. Nullam quis \nrisus eget urna mollis ornare vel eu leo.";

//////////////////////////////////// Setup. ////////////////////////////////////

void setup(){

  // setup display
  WIDTH = displayWidth;
  HEIGH = displayHeight;
  size(WIDTH, HEIGH, P2D);

  // setup Kinect
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();
  kinect.enableUser();
  kinect.alternativeViewPointDepthToImage();

  // setup Kinect Projector Toolkit
  kpc = new KinectProjectorToolkit(this, kinect.depthWidth(), kinect.depthHeight());
  kpc.loadCalibration("calibration.txt");
  kpc.setContourSmoothness(4);

  // setup OpenCV
  opencv = new OpenCV(this, kinect.depthWidth(), kinect.depthHeight());

  // setup drawing resources
  img = loadImage("texture.jpg");
  lCont = createGraphics(WIDTH, HEIGH, P2D);
  lText = createGraphics(WIDTH, HEIGH, P2D);
  inside_text_font = createFont(font_family, font_size);

  // setup joint array
  for (int i = 0; i < joints.length; i++) joints[i] = new PVector();

  PGraphics textGraphic = createGraphics(WIDTH, HEIGH, P2D);
  textGraphic.beginDraw();
  textGraphic.textFont(inside_text_font);
  textGraphic.textLeading(font_leading);
  textGraphic.fill(font_color);
  textGraphic.textAlign(LEFT, TOP);
  textGraphic.text(text_to_me, 0,0);
  textGraphic.endDraw();
  // img = textGraphic.get();

  mov  = new Movie(this, Integer.toString(((int) random(TOTAL_MOVS * 30)) % TOTAL_MOVS) + ".mp4");
  next = new Movie(this, Integer.toString(((int) random(TOTAL_MOVS * 30)) % TOTAL_MOVS) + ".mp4");
  mov.loop();
  // mov.volume(0);
  random(mov.duration());

  imageMode(CENTER);
  i_face  = loadImage("e/Emoji Smiley-01.png");
  i_heart = loadImage("heart.png");

}

/**
 * Draw each frame
 */
void draw() {
  background(0);
  kinect.update();
  kpc.setDepthMapRealWorld(kinect.depthMapRealWorld());

  drawUserContour();        // Draws the contour for the current user
  // drawFrameRate();       // For debugging: draws frame-rate.

  // For debugging: draws skeleton
  // int[] userList = kinect.getUsers();
  // for(int i=0; i<userList.length; i++) {
  //   // updateUserJoints(userList[i]);
  //   // drawUserProjectedSkeleton(userList[i]);
  //   // drawFace(userList[i]);
  // }

  // Change movie every 'next_mov' frames
  // on a separate thread, using method
  // "change movie". Loading a video file
  // is a slow operation, so if we don't
  // want to drop frames we have to do it
  // in a separate thread.
  if (frameCount % next_mov == 0) thread("changeMovie");

  // Unused feature.
  // if (frameCount % next_img == 0) thread("changeImage");
  // image(i_face,  200, 200, 40, 40); // For debugging the unused feature.

}

/**
 * Switch the movie that is currently playing
 */
void changeMovie() {
  next.loop();                        // Start looping the next movie
  next.volume(next_vol);              // Set the volume of the next movie
  next.jump(random(next.duration())); // Jump to a random point in the video
  mov.stop();                         // Stop the current movie
  mov = next;                         // Swap the movie. 'mov' is now 'next'.

  // Load the next movie onto 'next'. This
  // method is running as a separate thread
  // independent of the main drawing thread
  // so as slow as this operation might be,
  // it won't affect the performance of our
  // rendering.
  next = new Movie(this, Integer.toString(((int) random(TOTAL_MOVS * 30)) % TOTAL_MOVS) + ".mp4");

  // 'next_mov' is the number of frames
  // until the next movie plays. Make it
  // a random value between 60 (roughly
  // 2 seconds) and 200 (roughly 6.5
  // seconds).
  next_mov = int(random(60, 200));
}

/**
 * This method gets called whenever a frame
 * from a movie file is ready to be loaded.
 * We see for which movie file the frame is
 * ready for and make sure that movie file
 * is the one that reads.
 */
void movieEvent(Movie m) {
  if (m == mov) {
    mov.read();
  } else if (m == next) {
    next.read();
  }
}

/**
 * UNUSED FEATURE. Face overlay. Here
 * I was going for a face overlay,
 * a-la-Baldessari. Decided to omit
 * because it took from the theme of
 * the piece, and added just more noise.
 */

int long_image_duration = 90;      // about 3 secs;
int MIN_LONG_IMAGE_DURATION = 60;  // about 2 secs;
int MAX_LONG_IMAGE_DURATION = 120; // about 4 secs;
int next_long_image = 90;
int MIN_NEXT_LONG_IMAGE = 60;  // about 2 secs;
int MAX_NEXT_LONG_IMAGE = 120; // about 4 secs;

int SHORT_IMAGES_TO_LONG_IMAGE = 12;
int s = 0;

int NUM_FACES = 91;
int i = 1;

int SHORT_IMAGE_DURATION = 2;
int next_img = 2;

void changeImage() {
  i = ++i % NUM_FACES;
  String num = (i < 10) ? "0" + i : "" + i;
  i_face = loadImage("e/Emoji Smiley-" + num + ".png");
  if (++s == SHORT_IMAGES_TO_LONG_IMAGE) {
    next_img        = (int) random(MIN_LONG_IMAGE_DURATION, MAX_LONG_IMAGE_DURATION);
    next_long_image = (int) random(MIN_NEXT_LONG_IMAGE, MAX_NEXT_LONG_IMAGE);
    s = 0;
  } else {
    next_img = SHORT_IMAGE_DURATION;
  }
}

// void drawText(int userId) {
//   lText.beginDraw();
//   if (joints[SimpleOpenNI.SKEL_HEAD] != null) {
//     PVector pHead = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_HEAD]);
//     lText.textFont(inside_text_font);
//     lText.textLeading(font_leading);
//     lText.fill(font_color);
//     lText.textAlign(CENTER, TOP);
//     lText.text(text_to_me, pHead.x, pHead.y, pHead.z);
//   }
//   // lText.mask(pg);
//   lText.endDraw();
//   image(lText, 0, 0);
// }


/** ^^ everything above is for the
       unused face overlay feature. */


/**
 * Draws the frame rate in middle left of
 * the frame.
 */
void drawFrameRate() {
  textFont(inside_text_font);              // Set the font
  fill(#FFFFFF);                           // Set the color (white)
  textAlign(LEFT, TOP);                    // Set the anchor point
  text(Float.toString(frameRate), 0, 250); // Draw the frame rate
}

/**
 * Draws the contour of all visible users.
 */
void drawUserContour() {

  // Load image from kinect into OpenCV,
  // for finding the contour.
  kpc.setKinectUserImage(kinect.userImage());
  opencv.loadImage(kpc.getImage());

  // Get the contours
  projectedContours = new ArrayList<ProjectedContour>();
  ArrayList<Contour> contours = opencv.findContours();
  for (Contour contour : contours) {
    if (contour.area() < 2000) continue;
    ArrayList<PVector> cvContour = contour.getPoints();
    ProjectedContour projectedContour = kpc.getProjectedContour(cvContour, 1.0);
    projectedContours.add(projectedContour);
  }

  // Draw the outlines
  for (int i = 0; i < projectedContours.size(); i++) {
    ProjectedContour projectedContour = projectedContours.get(i);
    beginShape();
    texture(mov);
    for (PVector p : projectedContour.getProjectedContours()) {
      PVector t = projectedContour.getTextureCoordinate(p);
      vertex(p.x, p.y, mov.width * t.x, mov.height * t.y);
    }
    endShape();
  }
}

/**
 * FOR DEBUGING, and a deprecated feature.
 *  - Draws the full skeleton for all users.
 *  - Draws an overlay on the user's face.
 */
int j = 1;
void drawUserProjectedSkeleton(int userId) {
  if(kinect.isTrackingSkeleton(userId)) {
    PVector pHead           = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_HEAD]);
    PVector pNeck           = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_NECK]);
    PVector pLeftShoulder   = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_LEFT_SHOULDER]);
    PVector pRightShoulder  = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_RIGHT_SHOULDER]);
    PVector pLeftElbow      = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_LEFT_ELBOW]);
    PVector pRightElbow     = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_RIGHT_ELBOW]);
    PVector pLeftHand       = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_LEFT_HAND]);
    PVector pRightHand      = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_RIGHT_HAND]);
    PVector pTorso          = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_TORSO]);
    PVector pLeftHip        = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_LEFT_HIP]);
    PVector pRightHip       = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_RIGHT_HIP]);
    PVector pLeftKnee       = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_LEFT_KNEE]);
    PVector pRightKnee      = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_RIGHT_KNEE]);
    PVector pLeftFoot       = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_LEFT_FOOT]);
    PVector pRightFoot      = kpc.convertKinectToProjector(joints[SimpleOpenNI.SKEL_RIGHT_FOOT]);

    stroke(0, 0, 255);
    strokeWeight(16);
    line(pHead.x,           pHead.y, pNeck.x, pNeck.y);
    line(pNeck.x,           pNeck.y, pTorso.x, pTorso.y);
    line(pNeck.x,           pNeck.y, pLeftShoulder.x, pLeftShoulder.y);
    line(pLeftShoulder.x,   pLeftShoulder.y, pLeftElbow.x, pLeftElbow.y);
    line(pLeftElbow.x,      pLeftElbow.y, pLeftHand.x, pLeftHand.y);
    line(pNeck.x,           pNeck.y, pRightShoulder.x, pRightShoulder.y);
    line(pRightShoulder.x,  pRightShoulder.y, pRightElbow.x, pRightElbow.y);
    line(pRightElbow.x,     pRightElbow.y, pRightHand.x, pRightHand.y);
    line(pTorso.x,          pTorso.y, pLeftHip.x, pLeftHip.y);
    line(pLeftHip.x,        pLeftHip.y, pLeftKnee.x, pLeftKnee.y);
    line(pLeftKnee.x,       pLeftKnee.y, pLeftFoot.x, pLeftFoot.y);
    line(pTorso.x,          pTorso.y, pRightHip.x, pRightHip.y);
    line(pRightHip.x,       pRightHip.y, pRightKnee.x, pRightKnee.y);
    line(pRightKnee.x,      pRightKnee.y, pRightFoot.x, pRightFoot.y);

    fill(255, 0, 0);
    noStroke();
    ellipse(pHead.x,          pHead.y,          SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pNeck.x,          pNeck.y,          SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pTorso.x,         pTorso.y,         SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pLeftShoulder.x,  pLeftShoulder.y,  SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pRightShoulder.x, pRightShoulder.y, SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pLeftElbow.x,     pLeftElbow.y,     SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pRightElbow.x,    pRightElbow.y,    SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pLeftHand.x,      pLeftHand.y,      SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pRightHand.x,     pRightHand.y,     SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pLeftHip.x,       pLeftHip.y,       SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pRightHip.x,      pRightHip.y,      SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pLeftKnee.x,      pLeftKnee.y,      SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pRightKnee.x,     pRightKnee.y,     SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pLeftFoot.x,      pLeftFoot.y,      SIZE_JOINTS, SIZE_JOINTS);
    ellipse(pRightFoot.x,     pRightFoot.y,     SIZE_JOINTS, SIZE_JOINTS);

    // 700 - 5000
    float hscale = map(joints[SimpleOpenNI.SKEL_HEAD].z, 700, 5000, 180, 30);
    // float nscale = map(joints[SimpleOpenNI.SKEL_NECK].z, 700, 5000, 180, 30);

    image(i_face,  pHead.x, pHead.y, hscale, hscale);
    // image(i_heart, pNeck.x, pNeck.y, nscale, nscale);
  }
}

/**
 * Updates the joints array to have all
 * joints for user with id 'userId'
 */
void updateUserJoints(int userId) {
  for (int jointIdx = 0; jointIdx < 15; jointIdx++)
    kinect.getJointPositionSkeleton(userId, jointIdx, joints[jointIdx]);
}

//////////////////////////////// UNUSED METHODS ////////////////////////////////

void onNewUser(SimpleOpenNI curContext, int userId) {
  // next_vol = 1;
  // mov.volume(1);
  // curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId) {
  // if (kinect.getUsers().length == 0) {
  //   next_vol = 0;
  //   mov.volume(0);
  // }
}

void onVisibleUser(SimpleOpenNI curContext, int userId) {}
