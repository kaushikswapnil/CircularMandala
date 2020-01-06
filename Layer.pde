class Layer
{
   float m_Radius; 
   PVector m_StrokeColor;
   int m_NumLoops;
   float m_Angle;
   float m_AngleBetweenLoops;
   PVector m_Center;
   
   ArrayList<IEffect> m_Effects;
   
   Layer(float radius, int numLoops)
   {
     m_Radius = radius;
     m_NumLoops = numLoops;
     m_StrokeColor = new PVector(0, 0, 0);
     m_Angle = 0.0f;
     m_AngleBetweenLoops = TWO_PI/m_NumLoops;
     m_Center = CENTERVECTOR.copy();
     
     m_Effects = new ArrayList<IEffect>();
   }
   
   Layer(float radius, int numLoops, PVector strokeColor)
   {
     this(radius, numLoops);
     
     m_StrokeColor = strokeColor.copy();
   }
   
   void Update()
   {
     for (int effectIter = m_Effects.size()-1; effectIter >=0; --effectIter)
     {
        IEffect effect = m_Effects.get(effectIter);
        
        if (!effect.HasStarted()) 
        {
          effect.Start();
        }
        else if (effect.HasCompleted())
        {
          m_Effects.remove(effectIter);
          continue;
        }
        
        effect.Apply(this);
     }
   }
   
   void Display()
   {
     pushMatrix();

     translate(m_Center.x, m_Center.y);
     rotate(m_Angle);
     
     PVector flatPerimeterCircle = new PVector(0, m_Radius);
     stroke(m_StrokeColor.x, m_StrokeColor.y, m_StrokeColor.z);
     
     float diameter = 2*m_Radius;
     
     float curAngle = 0.0f;
     for (int loopIter = 0; loopIter < m_NumLoops; ++loopIter)
     {
       pushMatrix();
       
       PVector curPerimeterCircleCenter = flatPerimeterCircle.copy();
       curPerimeterCircleCenter.rotate(curAngle);
       ellipse(curPerimeterCircleCenter.x, curPerimeterCircleCenter.y, diameter, diameter);
       
       popMatrix();
       
       curAngle += m_AngleBetweenLoops;
     }
     
     popMatrix();
   }
   
   float GetIdealAngleBetweenLoops()
   {
     return TWO_PI/m_NumLoops;
   }
}
