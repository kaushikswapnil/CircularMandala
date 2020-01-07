int g_NumIterations = 12;
float g_LayerBaseRadii = 30.0f;
float g_LayerRadiiMultiplier = 1.02f;
int g_NumLayers = 8;
int g_BackgroungAlpha = 20;
float g_InitialAngleBetweenLoops = PI;
int g_GeneralLayerShapeMode = 0;
PVector NULLVECTOR = new PVector(0, 0, 0);
PVector CENTERVECTOR;
int g_RotationEffectModeStartFrame = -1;
int g_RotationEffectModeMinFrameCount = 100;
int g_StaticTimeStartFrame = -1;
int g_StaticTimeFrameCount = 10;
boolean g_Active = false;

ArrayList<Layer> g_Layers;

int g_EffectMode;

PVector[] g_LayerColors = {new PVector(255, 200, 0)
                          , new PVector(255, 150, 0)
                          , new PVector(255, 80, 60)
                          , new PVector(255, 255, 0)
                          , new PVector(0, 255, 255)
                          , new PVector(255, 0, 255)
                          , new PVector(255, 0, 0)
                          , new PVector(0, 255, 0)
                          , new PVector(0, 0, 255)
                          , new PVector(255, 255, 255)};

void setup()
{
  size(1000, 1000);
  
  CENTERVECTOR = new PVector(width/2, height/2);
  
  GenerateLayers();
  
  g_EffectMode = 0;
  
  g_Active = false;
  
  background(0);
}

void draw()
{    
  if (!g_Active)
  {
    return;
  }
  
  switch(g_EffectMode)
  {
     case 0:
     case 1:
     GradualGrowMode();
     break;
     
     case 2:
     case 3:
     UnfurlEffectMode();
     break;
     
     case 4:
     RotationEffectMode();
     break;
     
     case 5:
     if (g_StaticTimeStartFrame == -1)
     {
         g_StaticTimeStartFrame = frameCount;
     }
     else if (g_StaticTimeStartFrame + g_StaticTimeFrameCount < frameCount)
     {
         g_EffectMode = 6;
     }
     PerformLayerFrame();
     break;
     
     case 6:
     FurlEffectMode();
     break;
     
     default:
     PerformLayerFrame();
     break;
  }
}

void keyPressed()
{
  if (key == ' ')
  {
    g_Active = true;
  }
}

void GradualGrowMode()
{
 if (g_EffectMode == 0)
 {
   for (int layerIter = 0; layerIter < g_Layers.size(); ++layerIter)
   {
     float layerRadius = g_LayerBaseRadii + (g_LayerBaseRadii*layerIter*g_LayerRadiiMultiplier);
     Layer layer = g_Layers.get(layerIter);
     layer.m_Effects.add(new GradualGrowEffect(100, layerRadius));
     //layer.m_Effects.add(new RecedingCenteredEffect(180, 2.0f/3));
   }
   
   g_EffectMode = 1;
 }
 else //g_EffectMode == 1
 {
   if (!AnyLayerHasEffect())
   {
     g_EffectMode = 2;
     //g_EffectMode = 4;
   }
 }
 
 PerformLayerFrame();
}

void UnfurlEffectMode()
{
  if (g_EffectMode == 2)
  {
    for (Layer layer : g_Layers)
    {
      layer.m_Effects.add(new UnfurlFromCloseEffect(300));
    }
    
    g_EffectMode = 3;
  }
  else //g_EffectMode == 3
  {
    PerformLayerFrame();
    
    //If all effects are empty
    if (!AnyLayerHasEffect())
    {
       g_EffectMode = 4;//RotationMode 
    }
  }  
}

void RotationEffectMode()
{
  if (g_RotationEffectModeStartFrame == -1)
  {
    g_RotationEffectModeStartFrame = frameCount;
  }
  else if ((g_RotationEffectModeStartFrame + g_RotationEffectModeMinFrameCount) > frameCount)
  {
    for (Layer layer : g_Layers)
    {
       if (layer.m_Effects.size() == 0)
       {
         int rotationFrameDur = 350 + (int)random(200, 600);
         float rotationSign = (random(0,1) <= 0.5f ? 1.0f : -1.0f);
         float rotationAngleAmount = TWO_PI * ((random(0, 4) * 0.5f)+1.0f) * rotationSign;
         //int rotationFrameDur = 400;
         //float rotationAngleAmount = TWO_PI;
         layer.m_Effects.add(new InertialRotateEffect(rotationFrameDur, rotationAngleAmount, 0.3f, 0.1f, 2));
       }
    }
  }
  else
  {
    if (!AnyLayerHasEffect())
    {
       g_EffectMode = 5; 
       //g_RotationEffectModeStartFrame = frameCount;
    }
  }  
  
  PerformLayerFrame();
}

void FurlEffectMode()
{
  if (g_EffectMode == 6)
  {
    for (Layer layer : g_Layers)
    {
       layer.m_Effects.add(new ChangeAngleBetweenLoopEffect(100, -layer.m_AngleBetweenLoops));
       layer.m_Effects.add(new RotateEffect(200, -layer.m_Angle));
    }
    
    g_EffectMode = 7;
  }
  
  PerformLayerFrame();
}

void PerformLayerFrame()
{
  pushMatrix();
  
  rectMode(CENTER);
  fill(0, 0, 0, g_BackgroungAlpha);
  rect(CENTERVECTOR.x, CENTERVECTOR.y, width+10, height+10);

  noFill();
  
  strokeWeight(4.5f);
  
  for (Layer layer : g_Layers)
  {
     layer.Update();
     layer.Display(); 
  }
  
  popMatrix();
}

boolean AnyLayerHasEffect()
{
  boolean anyLayerHasEffect = false;
  for (Layer layer : g_Layers)
  {
    if (layer.m_Effects.size() > 0)
    {
      anyLayerHasEffect = true;
      break;
    }
  }
  
  return anyLayerHasEffect;
}

void GenerateLayers()
{
  g_Layers = new ArrayList<Layer>();

  for (int layerIter = 0; layerIter < g_NumLayers; ++layerIter)
  {
    float layerRadius = 0.0f;//g_LayerBaseRadii + (g_LayerBaseRadii*layerIter);
    g_Layers.add(new Layer(layerRadius, g_NumIterations, g_LayerColors[layerIter%g_LayerColors.length]));
    g_Layers.get(layerIter).m_AngleBetweenLoops = g_InitialAngleBetweenLoops;
    g_Layers.get(layerIter).m_ShapeMode = (int)(random(0,2));//g_GeneralLayerShapeMode;
  }
}
