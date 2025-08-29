import Phaser from 'phaser';

import { key } from '../constants';
import { Inventory } from './Player';

enum Animation {
  Left = 'player_left',
  Right = 'player_right',
  Up = 'player_up',
  Down = 'player_down',
}

interface Memory {
  system: string;
  user: string;
  gpt: string;
  currentPrompts: string[];
  result: boolean;
}

export class Agent extends Phaser.Physics.Arcade.Sprite {
  declare body: Phaser.Physics.Arcade.Body;
  selector: Phaser.Physics.Arcade.StaticBody;
  name: string;

  // private nameTag: Phaser.GameObjects.Text;
  private memory: Memory[] = [];
  private persona: string = "a helpful AI assistant";
  private instruction: string = "";
  private bias: string = "";
  private isBiased: boolean = false;

  private wasDragged: boolean = false; // if user drag the agent now

  private biasType: string = "";
  public setBiasType(type: string) {
    this.biasType = type;
  }
  public getBiasType() {
    return this.biasType;
  }


  // ===== 在类字段区域，替换你现在的这些静态字段 =====
  public static biasedAgentsCount: number = 0;     // 当前“被标为幻觉”的数量
  public static maxAllowedBiased: number = 1;      // 允许的最大数量（L1=1，L2=2，L3=3）
  public static biasedOrder: Agent[] = [];         // 记录选择顺序（用于“满额时替换最早的”）
  public static currentBiasedAgent: Agent | null = null; // 保留：指向“最近一次被选中”的

  // ===== 重置方法：同时清空顺序队列 =====
  public static resetBiasedAgentsCount() {
    Agent.biasedAgentsCount = 0;
    Agent.currentBiasedAgent = null;
    Agent.biasedOrder = [];
  }

  // （可选）在切关的时候调用：Agent.maxAllowedBiased = 2/3；并 resetBiasedAgentsCount()

  public assignToWorkplace: boolean = false;
  private activationFunction: (state: any) => any = (state: any) => {
    console.log(`---Step for Agent: ${this.name}---`);
    return state;
  };

  public inventory: Inventory = {
      promptUtils: [],
      tools: [],
    }

  constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    texture:any = key.atlas.player,
    frame:any = 'misa-front',
    name: string = "Agent",
    persona: string = "a helpful AI assistant",
    bias: string = ""
  ) {
    super(scene, x, y, texture, frame);

    this.name = name;
    this.persona = persona;

    // this.nameTag = scene.add.text(x, y - 20, name, {
    //     fontSize: '14px',
    //     color: '#ffffff',
    //     backgroundColor: '#00000088',
    //     padding: { x: 4, y: 2 },
    //     align: 'center',
    //   }).setOrigin(0.5, 1); 

    // this.nameTag.setDepth(10);
    
    // Add the sprite to the scene
    scene.add.existing(this);

    // Enable physics for the sprite
    scene.physics.world.enable(this);
    scene.physics.add.existing(this);

    // The image has a bit of whitespace so use setSize and
    // setOffset to control the size of the player's body
    this.setSize(32, 42).setOffset(0, 22);

    // Collide the sprite body with the world boundary
    this.setImmovable(true);
    this.body.setAllowGravity(false);
    this.setCollideWorldBounds(true);


    // Create sprite animations
    this.createAnimations(key.atlas.player);

    // this.createWorkAnimations(key.atlas.work);

    this.selector = scene.physics.add.staticBody(x - 8, y + 32, 16, 16);

    // this.setInteractive({ useHandCursor: true });
    // scene.input.on('gameobjectdown', this.onClick, this);

    this.setInteractive({ useHandCursor: true, draggable: true }); // 允许拖拽
    scene.input.setDraggable(this);

    // 监听拖拽事件
    // scene.input.on('dragstart', (pointer:any, gameObject:any) => {
    //   if (gameObject === this) {
    //     this.setTint(0xff0000); // 拖拽开始时变红
    //   }
    // });

    // scene.input.on('drag', (pointer:any, gameObject:any, dragX:number, dragY:number) => {
    //   if (gameObject === this) {
    //     this.x = dragX;
    //     this.y = dragY;
    //     // this.nameTag.setPosition(this.x, this.y - 25); 
    //   }
    // });

    //     scene.input.on('dragend', (pointer:any, gameObject:any) => {
    //   if (gameObject === this) {
    //     this.clearTint(); // 结束拖A拽后恢复原色
    //   }
    // });


    scene.input.on('dragstart', (pointer: any, gameObject: any) => {
      if (gameObject === this) {
        this.wasDragged = false;
        this.setTint(0xff0000);
      }
    });

    scene.input.on('drag', (pointer: any, gameObject: any, dragX: number, dragY: number) => {
      if (gameObject === this) {
        this.isDrag = true; // 设置拖拽状态
        this.x = dragX;
        this.y = dragY;
        this.wasDragged = true;
        // this.nameTag.setPosition(this.x, this.y - 25);
      }
    });

    scene.input.on('dragend', (pointer: any, gameObject: any) => {
      if (gameObject === this) {
        this.clearTint();
      }
    });

    // this.on('pointerdown', (pointer:any) => {
    //   this.onClick(pointer, this);
    // });

    this.on('pointerup', (pointer: any) => {
      if (!this.wasDragged) {
        this.onClick(pointer, this);
      }
    });
  }

  update() {
    // this.nameTag.setPosition(this.x, this.y - 25);
  }

  public getName(){
    return this.name;
  }

  public getBias(){
    if(this.isBiased)return this.bias;
    else return "";
  }
  
  public setBias(bias: string){
    this.bias = bias;
  }

  public changeNameTagColor(color: string){
    // this.nameTag.setColor(color);
  } 

  public storeMemory(system: string, user: string, gpt: string, currentPrompts: string[], result: boolean) {
    this.memory.push({ system, user, gpt, currentPrompts, result });
  }

  public getMemory() {
    return this.memory;
  }

  public getPersona() {
    return this.persona;
  }

  public activate() {
        return this.activationFunction;
    }

  public setActivationFunction(activationFunction: (state: any)=>any) {
      this.activationFunction = activationFunction;
  }

  public moveSelector(animation: Animation) {
    const { body, selector } = this;

    switch (animation) {
      case Animation.Left:
        selector.x = body.x - 19;
        selector.y = body.y + 14;
        break;

      case Animation.Right:
        selector.x = body.x + 35;
        selector.y = body.y + 14;
        break;

      case Animation.Up:
        selector.x = body.x + 8;
        selector.y = body.y - 18;
        break;

      case Animation.Down:
        selector.x = body.x + 8;
        selector.y = body.y + 46;
        break;
    }
  }

  public setInstruction(instruction: string) {
      this.instruction = instruction;
    }

  public getInstruction() {
      return this.instruction;
  }

  public addPromptUtils(promptUtils: string) {
      this.inventory.promptUtils.push(promptUtils);
    }
    
  public getPromptUtils() {
    return [...this.inventory.promptUtils];
  }


  public setTexture(key: string, frame?: string | number): this {
      super.setTexture(key, frame);
      return this;
  }

  // private onClick(pointer: Phaser.Input.Pointer, gameObject: Phaser.GameObjects.GameObject) {
  //   if (gameObject === this) {
  //     console.log(`Agent ${this.name} clicked!`);

  //     // If there is already another biased agent, restore it first.        
  //     if (Agent.currentBiasedAgent && Agent.currentBiasedAgent !== this) {
  //       Agent.currentBiasedAgent.setToUnbiased();
  //     }

  //     if (!this.isBiased) {
  //       // Set to biased
  //       this.name = "Biased " + this.name;
  //       this.isBiased = true;
  //       this.setTexture(key.atlas.bias);
  //       this.createAnimations(key.atlas.bias);
  //       this.bias = 'biased';
  //       Agent.biasedAgentsCount = 1;
  //       Agent.currentBiasedAgent = this;

  //       console.log("Agent is now biased:", this.name);
  //     }
  //   }
  // }

  private static rebalanceBiasTypes(scene: Phaser.Scene) {
    const pool = (scene.registry.get('biasTypePool') as string[]) || ['factual'];
    const list = Agent.biasedOrder; // 从最早到最近
    if (pool.length === 0) return;

    for (let i = 0; i < list.length; i++) {
      const t = pool[i % pool.length]; // 👈 用取模，不再用“最后一个兜底”
      list[i].setBiasType(t);
    }
  }

  private onClick(pointer: Phaser.Input.Pointer, gameObject: Phaser.GameObjects.GameObject) {
    if (gameObject !== this) return;

    if (this.isBiased) return;

    if (Agent.biasedAgentsCount < Agent.maxAllowedBiased) {
      this.setToBiased();
    } else {
      const oldest = Agent.biasedOrder.shift();
      if (oldest && oldest !== this) {
        oldest.setToUnbiased();
      }
      this.setToBiased();
    }
  }
    
  public setToBiased() {
    if (this.isBiased) return;

    if (!/^Biased\s+/.test(this.name)) this.name = 'Biased ' + this.name;
    this.isBiased = true;
    this.setTexture(key.atlas.bias);
    this.createAnimations(key.atlas.bias);
    this.bias = 'biased';

    Agent.biasedAgentsCount++;
    Agent.currentBiasedAgent = this;
    Agent.biasedOrder.push(this);

    // 👇 统一按队列位置分配类型
    Agent.rebalanceBiasTypes(this.scene);

    // 可选：打印最终分配结果核对
    const myIdx = Agent.biasedOrder.indexOf(this);
    console.log('[bias:assign]', {
      pool: this.scene.registry.get('biasTypePool'),
      myIdx,
      myType: this.getBiasType(),
      name: this.name,
    });
  }


  public setToUnbiased() {
    if (!this.isBiased) return;

    // 视觉与状态
    this.name = this.name.replace(/^Biased\s+/, "");
    this.isBiased = false;
    this.setTexture(key.atlas.player);
    this.createAnimations(key.atlas.player);

    // 计数与队列清理
    Agent.biasedAgentsCount = Math.max(0, Agent.biasedAgentsCount - 1);

    // 从顺序队列移除自己
    const idx = Agent.biasedOrder.indexOf(this);
    if (idx >= 0) Agent.biasedOrder.splice(idx, 1);

    // 如果当前指针指向自己，则设为“最近一个”，否则置空
    if (Agent.currentBiasedAgent === this) {
      Agent.currentBiasedAgent = Agent.biasedOrder.length
        ? Agent.biasedOrder[Agent.biasedOrder.length - 1]
        : null;
    }

    // 清除“偏置语义”
    this.bias = '';
    this.setBiasType('');
    console.log("Agent is now unbiased:", this.name);
    Agent.rebalanceBiasTypes(this.scene);
  }

  private createWorkAnimations(atlasKey: string) {
    const anims = this.scene.anims;
  
    const baseKey = this.name;
        
    const animList = [
      { key: 'player_work', prefix: 'misa-work.' },
    ];
  
    for (const { key, prefix } of animList) {
      const fullKey = `${baseKey}_${key}`;
  
      if (anims.exists(fullKey)) anims.remove(fullKey);
  
      anims.create({
        key: fullKey,
        frames: anims.generateFrameNames(atlasKey, {
          prefix,
          start: 0,
          end: 11,
          zeroPad: 3,
        }),
        frameRate: 10,
        repeat: -1,
      });
    }
  }

  public setAgentState(state: 'work' | 'idle') {
    if (state === 'work') {
      if (!this.isBiased) {
        this.setTexture(key.atlas.workPlayer);
        this.createWorkAnimations(key.atlas.workPlayer);
        this.anims.play(`${this.name}_player_work`, true);
      } else {
        this.setTexture(key.atlas.workBias);
        this.createWorkAnimations(key.atlas.workBias);
        this.anims.play(`${this.name}_player_work`, true);
      }
    } else {
      this.anims.stop();
      this.setTexture(this.isBiased ? key.atlas.bias : key.atlas.player);
      this.createAnimations(this.isBiased ? key.atlas.bias : key.atlas.player);
    }
  }

  private createAnimations(atlasKey: string) {
    const anims = this.scene.anims;
  
    const baseKey = this.name;
  
    const animList = [
      { key: Animation.Left, prefix: 'misa-left-walk.' },
      { key: Animation.Right, prefix: 'misa-right-walk.' },
      { key: Animation.Up, prefix: 'misa-back-walk.' },
      { key: Animation.Down, prefix: 'misa-front-walk.' },
    ];
  
    for (const { key, prefix } of animList) {
      const fullKey = `${baseKey}_${key}`;
  
      if (anims.exists(fullKey)) anims.remove(fullKey);
  
      anims.create({
        key: fullKey,
        frames: anims.generateFrameNames(atlasKey, {
          prefix,
          start: 0,
          end: 5,
          zeroPad: 3,
        }),
        frameRate: 10,
        repeat: -1,
      });
    }
  }
}