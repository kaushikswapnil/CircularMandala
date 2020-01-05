int g_NumIterations = 12;
float g_LayerBaseRadii = 50.0f;
float g_LayerRadiiMultiplier = 1.39f;
int g_NumLayers = 4;
int g_BackgroungAlpha = 20;

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
  
  GenerateLayers();
  
  g_EffectMode = 0;
}

void draw()
{    
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
     
     default:
     PerformLayerFrame();
     break;
  }
}

void GradualGrowMode()
{
 if (g_EffectMode == 0)
 {
   for (int layerIter = 0; layerIter < g_Layers.size(); ++layerIter)
   {
     float layerRadius = g_LayerBaseRadii + (g_LayerBaseRadii*layerIter);
     Layer layer = g_Layers.get(layerIter);
     layer.m_Effects.add(new GradualGrowEffect(100, layerRadius));
   }
   
   g_EffectMode = 1;
 }
 else //g_EffectMode == 1
 {
   if (!AnyLayerHasEffect())
   {
     g_EffectMode = 2;
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
  for (Layer layer : g_Layers)
  {
     if (layer.m_Effects.size() == 0)
     {
       int rotationFrameDur = 350 + (int)random(200, 600);
       float rotationAngleAmount = TWO_PI * ((random(-2, 2)*0.5f)+1);
       layer.m_Effects.add(new InertialRotateEffect(rotationFrameDur, rotationAngleAmount, 0.3f, 0.1f, 2));
     }
  }
  
  PerformLayerFrame();
}

void PerformLayerFrame()
{
  pushMatrix();
  translate(width/2, height/2);
  
  rectMode(CENTER);
  fill(0, 0, 0, g_BackgroungAlpha);
  rect(0, 0, width+10, height+10);

  noFill();
  
  strokeWeight(3.5f);
  
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
    g_Layers.add(new Layer(layerRadius, g_NumIterations, g_LayerColors[layerIter]));
    g_Layers.get(layerIter).m_AngleBetweenLoops = 0.0f;
  }
}
