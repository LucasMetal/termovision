class Grid{

  int width, height, step, x, y, xLine, yLine, speedX, speedY, endTime;
  Boolean show;
  PGraphics g;
  
  Grid (int x, int y, int width, int height, int step, int speed){
    this.width = width;
    this.height = height;
    this.step = step;
    this.x = x;
    this.y = y;
    this.xLine = 0;
    this.yLine = 0;
    this.speedX = speed;
    this.speedY = speed;
    
    initGrid();    
  }
  
  void initGrid(){
    g = createGraphics(width+1, height+1); // +1 so it shows the border
    g.beginDraw();
    g.stroke(255);
    
    // Vertical lines
    int stepInc = width/step;    
    for (int i = 0; i <= step; i++ ) {      
      g.line(i*stepInc, 0, i*stepInc, height);
    }
    
    // Horizontal lines
    stepInc = height/step;
    for (int i = 0; i <= step; i++ ) {      
      g.line(0, i*stepInc, width, i*stepInc);
    }
    
    g.endDraw();    
  }
  
  void show(int seconds){
    show = true;
    endTime = millis() + seconds * 1000;
  }
  
  void update(int t){
    
    if (!show) return;
    
    xLine += speedX;
    yLine += speedY;
    
    if (xLine < 0 || xLine > width) speedX *= -1;
    if (yLine < 0 || yLine > height) speedY *= -1;
    
    if (t > endTime) show = false; 
  }
  
  void draw ()
  {
    if (!show) return;
    
    image(g, x, y);
    
    stroke(255);
    strokeWeight(5);
    line(x + xLine, y, x + xLine, y + height);
    line(x, y + yLine, x + width, y + yLine);
  }
}
