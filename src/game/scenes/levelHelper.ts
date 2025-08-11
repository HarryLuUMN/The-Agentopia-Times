// levelHelper.ts
import Phaser from 'phaser';

/* History */

interface HistoryRecord {
  timestamp: string;
  score: number;
}

const HISTORY_KEY_PREFIX = "level_history_";

// Save scores
export function saveHistory(level: string, score: number) {
  const key = HISTORY_KEY_PREFIX + level;
  const raw = localStorage.getItem(key);
  const history: HistoryRecord[] = raw ? JSON.parse(raw) : [];

  history.push({
    timestamp: new Date().toLocaleString(),
    score,
  });

  localStorage.setItem(key, JSON.stringify(history));
  console.log(`[History] Saved for ${level}:`, score);
}

// Create a button in the bottom right corner and click Show History
export function createHistoryButton(scene: Phaser.Scene, level: string) {
  const screenWidth = scene.cameras.main.width;
  const screenHeight = scene.cameras.main.height;

  const button = scene.add.text(screenWidth - 100, screenHeight - 40, '📜 History', {
    fontSize: '18px',
    fontFamily: 'Verdana',
    color: '#ffffff',
    backgroundColor: '#000000',
    padding: { x: 10, y: 5 },
  })
    .setOrigin(0.5)
    .setScrollFactor(0)
    .setDepth(2000)
    .setInteractive();

  button.on('pointerdown', () => {
    showHistory(scene, level);
  });
}

// Display history
function showHistory(scene: Phaser.Scene, level: string) {
  const key = HISTORY_KEY_PREFIX + level;
  const raw = localStorage.getItem(key);
  const history: HistoryRecord[] = raw ? JSON.parse(raw) : [];

  // If it already exists, just close it
  const existingUI = scene.children.getAll().filter(obj => obj.getData && obj.getData('isHistoryUI'));
  if (existingUI.length > 0) {
    existingUI.forEach(obj => obj.destroy());
    return;
  }

  const boxWidth = 450;
  const boxHeight = 300;
  const centerX = scene.cameras.main.centerX;
  const centerY = scene.cameras.main.centerY;

  // Background
  const bg = scene.add.rectangle(centerX, centerY, boxWidth, boxHeight, 0x000000, 0.8)
    .setScrollFactor(0)
    .setDepth(2999)
    .setStrokeStyle(2, 0xffffff)
    .setInteractive()
    .setData('isHistoryUI', true);

  if (history.length === 0) {
    const noDataBg = scene.add.rectangle(centerX, centerY, boxWidth, boxHeight, 0x000000, 0.8)
      .setScrollFactor(0)
      .setDepth(2999)
      .setStrokeStyle(2, 0xffffff)
      .setInteractive()
      .setData('isHistoryUI', true);

    const noDataText = scene.add.text(centerX, centerY, "No history yet!", {
      fontSize: '20px',
      fontFamily: 'Verdana',
      color: '#ffffff',
    })
      .setOrigin(0.5)
      .setScrollFactor(0)
      .setDepth(3000)
      .setData('isHistoryUI', true);

    // Click on the background to close it
    noDataBg.on('pointerdown', () => {
      scene.children.getAll().forEach(obj => {
        if (obj.getData && obj.getData('isHistoryUI')) obj.destroy();
      });
    });

    return;
  }


  // Historical texts
  const textLines = history.map((h, i) => `${i + 1}. [${h.timestamp}]  Score: ${h.score}`);
  const historyText = scene.add.text(centerX - boxWidth / 2 + 20, centerY - boxHeight / 2 + 20,
    textLines.join('\n'),
    {
      fontSize: '16px',
      fontFamily: 'Verdana',
      color: '#ffffff',
      wordWrap: { width: boxWidth - 40 }
    })
    .setOrigin(0, 0)
    .setScrollFactor(0)
    .setDepth(3000)
    .setData('isHistoryUI', true);

  // 添加遮罩实现滚动
  const maskShape = scene.make.graphics({});
  maskShape.fillStyle(0xffffff);
  maskShape.fillRect(centerX - boxWidth / 2 + 10, centerY - boxHeight / 2 + 10, boxWidth - 20, boxHeight - 60);
  const mask = maskShape.createGeometryMask();
  historyText.setMask(mask);

  let scrollY = 0;
  scene.input.on('wheel', (_pointer: any, _dx: number, dy: number) => {
    if (scene.children.exists(historyText)) {
      scrollY -= dy * 0.5;
      const maxScroll = Math.max(0, historyText.height - (boxHeight - 60));
      scrollY = Phaser.Math.Clamp(scrollY, -maxScroll, 0);
      historyText.y = centerY - boxHeight / 2 + 20 + scrollY;
    }
  });

  // Clear History button
  const clearBtn = scene.add.text(centerX, centerY + boxHeight / 2 - 20, '🗑 Clear History', {
    fontSize: '16px',
    fontFamily: 'Verdana',
    color: '#ff6666',
    backgroundColor: '#222222',
    padding: { x: 8, y: 4 },
  })
    .setOrigin(0.5)
    .setScrollFactor(0)
    .setDepth(3001)
    .setInteractive()
    .setData('isHistoryUI', true);

  clearBtn.on('pointerdown', (pointer: Phaser.Input.Pointer, localX: number, localY: number, event: Phaser.Types.Input.EventData) => {
    event.stopPropagation();

    localStorage.removeItem(key);
    scene.children.getAll().forEach(obj => {
      if (obj.getData && obj.getData('isHistoryUI')) obj.destroy();
    });
    console.log(`[History] Cleared for ${level}`);
  });

  bg.on('pointerdown', () => {
    scene.children.getAll().forEach(obj => {
      if (obj.getData && obj.getData('isHistoryUI')) obj.destroy();
    });
  });
}
