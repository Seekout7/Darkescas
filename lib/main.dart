// ═══════════════════════════════════════════════════════════════════════════════
//                          OYUN SONU İŞLEYİCİLER
// ═══════════════════════════════════════════════════════════════════════════════

  /// Oyunu sonlandıran ve tüm client'lara bildiren metod (host tarafında)
  void endGame(int winningTeam, String message) {
    if (currentPage != 3 || winnerTeam != 0) return;

    winnerTeam = winningTeam;
    endGameMessage = message;

    broadcastToAll({'t': 'over', 'p': {'w': winningTeam, 'm': message}});
    handleGameOver(winningTeam, message);
  }

  /// Client tarafında oyun sonu ekranına geçiş yapan metod
  void handleGameOver(int winningTeam, String message) {
    if (currentPage == 4) return;

    winnerTeam = winningTeam;
    endGameMessage = message;
    currentPage = 4;

    gameLoopTimer?.cancel();
    gameLoopTimer = null;

    refreshUI();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                          OYUNCU ÇIKARMA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Belirtilen oyuncuyu oyundan çıkaran metod
  /// Host ayrılırsa oyun sona erer
  void removePlayer(int playerId) {
    if (playerId == 0) return;

    if (currentPage == 3 && playerId == guardPlayerId) {
      playerList.removeWhere((p) => p.playerId == playerId);
      playerEndpoints.remove(playerId);
      endGame(2, 'Guvenlik gorevlisi ayrildi. Animatronikler kazandi!');
      return;
    }

    playerList.removeWhere((p) => p.playerId == playerId);
    playerEndpoints.remove(playerId);

    if (currentPage == 2) {
      broadcastLobbyUpdate();
    } else if (currentPage == 3 && !playerList.any((p) => p.playerRole == 1 && p.isAlive)) {
      endGame(1, 'Tum animatronikler yok edildi. Guvenlik kazandi!');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                          YARDIMCI FONKSİYONLAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// ID'ye göre oyuncu bulan metod
  PlayerNetworkState? findPlayerById(int playerId) {
    for (var player in playerList) {
      if (player.playerId == playerId) return player;
    }
    return null;
  }

  /// Pozisyona göre oda ID'si bulan metod
  int getRoomAtPosition(Offset position) {
    if (currentGameMap == null) return -1;
    if (currentGameMap!.officeRect.contains(position)) return -2;

    for (int i = 0; i < currentGameMap!.rooms.length; i++) {
      if (currentGameMap!.rooms[i].roomRect.contains(position)) return i;
    }
    return -1;
  }

  /// Rastgele spawn pozisyonu üreten metod
  Offset getRandomSpawnPosition() {
    if (currentGameMap == null || currentGameMap!.rooms.isEmpty) {
      return const Offset(-30.0, 0.0);
    }

    final room = currentGameMap!.rooms[randomGenerator.nextInt(currentGameMap!.rooms.length)].roomRect;
    final marginX = min(1.0, room.width * 0.25);
    final marginY = min(1.0, room.height * 0.25);

    double x1 = room.left + marginX, x2 = room.right - marginX;
    double y1 = room.top + marginY, y2 = room.bottom - marginY;

    if (x2 < x1) x1 = x2 = room.center.dx;
    if (y2 < y1) y1 = y2 = room.center.dy;

    return Offset(x1 + randomGenerator.nextDouble() * (x2 - x1),
        y1 + randomGenerator.nextDouble() * (y2 - y1));
  }

  /// Kullanılmayan karakter ID'si bulan metod
  int getFreeCharacterId(List<int> usedIds) {
    for (int i = 0; i < 100; i++) {
      int candidate = randomGenerator.nextInt(characterDefinitions.length);
      if (!usedIds.contains(candidate)) return candidate;
    }
    for (int c = 0; c < characterDefinitions.length; c++) {
      if (!usedIds.contains(c)) return c;
    }
    return 0;
  }

  /// Karakter ID'sine göre isim döndüren metod
  String getCharacterName(int characterId) {
    if (characterId < 0 || characterId >= characterDefinitions.length) return '?';
    return characterDefinitions[characterId].characterName;
  }

  /// Karakter ID'sine göre renk döndüren metod
  Color getCharacterColor(int characterId) {
    if (characterId < 0 || characterId >= characterDefinitions.length) return Colors.white;
    return characterDefinitions[characterId].characterColor;
  }

  /// Görünür oyuncu listesi oluşturan metod
  List<RemotePlayerVisual> getVisiblePlayers() {
    final List<RemotePlayerVisual> visibleList = [];

    if (isHostDevice) {
      for (var player in playerList) {
        if (!player.isAlive) continue;
        visibleList.add(RemotePlayerVisual(
          player.playerId,
          player.characterId,
          player.playerRole,
          player.positionX,
          player.positionY,
          player.currentRoomId,
          player.isMoving,
          isPlayerHidden(player),
          player.isInsideOffice,
          player.playerRole == 0 ? Colors.cyan : getCharacterColor(player.characterId),
        ));
      }
    } else {
      remotePlayers.forEach((id, player) {
        if (id != myPlayerId) visibleList.add(player);
      });

      if (myPlayerId != -1 && myRole != -1) {
        visibleList.add(RemotePlayerVisual(
          myPlayerId,
          myCharacterId,
          myRole,
          playerPosition.dx,
          playerPosition.dy,
          getRoomAtPosition(playerPosition),
          isPlayerMoving,
          false,
          isPlayerInsideOffice,
          myRole == 0 ? Colors.cyan : getCharacterColor(myCharacterId),
        ));
      }
    }

    return visibleList;
  }

  /// Kamera detaylarını döndüren metod
  String getCameraDetails() {
    if (currentGameMap == null || cameraRoomIndex < 0 || cameraRoomIndex >= currentGameMap!.rooms.length) {
      return '';
    }
    if (cameraJamEndTime > gameTime) return 'PARAZIT - SINYAL BOZULDU';

    final List<String> detectedNames = [];

    for (var visual in getVisiblePlayers()) {
      if (visual.playerRole != 0 && !visual.isInsideOffice && 
          visual.roomId == cameraRoomIndex && visual.isMoving && !visual.isHidden) {
        detectedNames.add(getCharacterName(visual.characterId));
      }
    }

    String result = '';
    if (noiseRoomId == cameraRoomIndex && noiseEndTime > gameTime) result += 'SES ALGILANDI! ';
    result += detectedNames.isEmpty ? 'Alan temiz.' : 'HAREKET: ${detectedNames.join(', ')}';

    return result;
  }

  /// Oyun saatini hesaplayan metod (12:00 AM -> 6:00 AM)
  String getGameClock() {
    final double progress = (gameTime / nightDuration).clamp(0.0, 1.0);
    final int totalMinutes = (progress * 6 * 60).toInt();
    final int hour = totalMinutes ~/ 60;
    final int minute = totalMinutes % 60;
    final int hour12 = hour == 0 ? 12 : hour;
    return '$hour12:${minute.toString().padLeft(2, '0')} AM';
  }

  /// Belirtilen tarafta tehlike olup olmadığını kontrol eden metod
  bool isDangerAtSide(int side) {
    if (currentGameMap == null) return false;
    final doorPos = side == 0 ? currentGameMap!.leftDoorPosition : currentGameMap!.rightDoorPosition;

    for (var visual in getVisiblePlayers()) {
      if (visual.playerRole == 1 && !visual.isInsideOffice && !visual.isHidden &&
          (Offset(visual.positionX, visual.positionY) - doorPos).distance < 3.5) {
        return true;
      }
    }
    return false;
  }

  /// Ventte tehlike olup olmadığını kontrol eden metod
  bool isVentDangerous() {
    if (currentGameMap == null) return false;
    for (var visual in getVisiblePlayers()) {
      if (visual.playerRole == 1 && !visual.isInsideOffice && !visual.isHidden &&
          (Offset(visual.positionX, visual.positionY) - currentGameMap!.ventPosition).distance < 3.5) {
        return true;
      }
    }
    return false;
  }

  /// Mevcut güç kullanım seviyesini hesaplayan metod
  int calculatePowerUsage() {
    int usage = 1;
    if (leftDoorClosed) usage++;
    if (rightDoorClosed) usage++;
    if (flashlightOn) usage++;
    if (cameraSystemOn) usage++;
    return usage;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                          UI YARDIMCI WIDGET'LARI
  // ═══════════════════════════════════════════════════════════════════════════

  Widget buildVignetteEffect() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0x00000000), Color(0x99000000)],
              stops: [0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Offset calculateShakeOffset(double multiplier) {
    if (!qualitySettings.screenShakeEnabled || screenShakeIntensity <= 0.01) return Offset.zero;
    return Offset((randomGenerator.nextDouble() - 0.5) * screenShakeIntensity * multiplier,
        (randomGenerator.nextDouble() - 0.5) * screenShakeIntensity * multiplier * 0.6);
  }

  Widget buildAnimatronicBody(Color color, double height, {bool glow = false, int kind = 0}) {
    return SizedBox(
      width: height * 0.66,
      height: height,
      child: CustomPaint(painter: AnimatronicPainter(color, glow, kind)),
    );
  }

  Widget buildGameCard(Widget child, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.only(bottom: 10.0),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          border: Border.all(color: const Color(0xFF3A0000), width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: child,
      ),
    );
  }

  Widget buildFnafButton(String label, Color color, VoidCallback? onTap) {
    final bool disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFF1A1A1A)
              : Color.fromARGB(70, getColorRed(color), getColorGreen(color), getColorBlue(color)),
          border: Border.all(
              color: disabled ? Colors.grey.shade800 : color, width: 2.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled ? Colors.grey : color,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                          ANA BUILD METODU
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('DARKESCAS',
            style: TextStyle(
                color: Color(0xFFB00000),
                fontFamily: 'monospace',
                letterSpacing: 3.0)),
        actions: [
          PopupMenuButton<GameQualityLevel>(
            initialValue: currentQuality,
            onSelected: setQualityLevel,
            itemBuilder: (context) => [
              const PopupMenuItem(value: GameQualityLevel.low, child: Text('Dusuk')),
              const PopupMenuItem(value: GameQualityLevel.medium, child: Text('Orta')),
              const PopupMenuItem(value: GameQualityLevel.high, child: Text('Yuksek')),
            ],
          ),
        ],
      ),
      body: SafeArea(child: buildCurrentPage()),
    );
  }

  Widget buildCurrentPage() {
    switch (currentPage) {
      case 0: return buildMainMenuPage();
      case 1: return buildDiscoveryPage();
      case 2: return buildLobbyPage();
      case 3: return buildGamePage();
      case 4: return buildGameOverPage();
      default: return buildMainMenuPage();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                          SAYFA 0: ANA MENÜ
  // ═══════════════════════════════════════════════════════════════════════════

  Widget buildMainMenuPage() {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const SizedBox(height: 10.0),
        const Text('DARKESCAS',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 34.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB00000),
                fontFamily: 'monospace',
                letterSpacing: 4.0)),
        const Text('GECE GUVENLIGI - LAN KORKU OYUNU',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey,
                fontFamily: 'monospace',
                fontSize: 11.0,
                letterSpacing: 2.0)),
        const SizedBox(height: 6.0),
        Text('KALITE: ${getQualityName()} (sag ustten degistir)',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 10.0)),
        const SizedBox(height: 30.0),
        
        TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            labelText: 'Oyuncu Adiniz',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3A0000)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB00000)),
            ),
          ),
        ),
        const SizedBox(height: 20.0),
        
        buildGameCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HOST OL', style: TextStyle(color: Color(0xFFB00000), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4.0),
              const Text('Yeni bir oyun lobisi olustur ve arkadaslarinin sana baglanmasini bekle.',
                  style: TextStyle(color: Colors.grey, fontSize: 12.0)),
            ],
          ),
          onTap: hostNewGame,
        ),
        
        buildGameCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LOBI ARA', style: TextStyle(color: Color(0xFFB00000), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4.0),
              const Text('WiFi agindaki aktif hostlari otomatik olarak kesfet.',
                  style: TextStyle(color: Colors.grey, fontSize: 12.0)),
            ],
          ),
          onTap: openDiscovery,
        ),
        
        const SizedBox(height: 10.0),
        TextField(
          controller: ipController,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: InputDecoration(
            labelText: 'IP Adresi ile Baglan',
            labelStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3A0000)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB00000)),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.login, color: Color(0xFFB00000)),
              onPressed: joinByIpAddress,
            ),
          ),
        ),
        
        const SizedBox(height: 20.0),
        if (statusMessage.isNotEmpty)
          Text(statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB00000), fontFamily: 'monospace')),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                          SAYFA 1: HOST KEŞİFİ
  // ═══════════════════════════════════════════════════════════════════════════

  Widget buildDiscoveryPage() {
    return Column(
      children: [
        AppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          title: const Text('LOBI ARANIYOR...', style: TextStyle(fontFamily: 'monospace')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: returnToMainMenu,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: discoveredHosts.length,
            itemBuilder: (context, index) {
              final host = discoveredHosts[index];
              return buildGameCard(
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(host.lobbyName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace')),
                          Text('${host.hostAddress}:${host.hostPort}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11.0)),
                          Text('${host.playerCount}/$maximumPlayers oyuncu - Harita: ${host.selectedMapIndex == 1 ? 'Depo' : 'Ofis'}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11.0)),
                        ],
                      ),
                    ),
                    buildFnafButton('KATIL', const Color(0xFFB00000), () => joinDiscoveredHost(host)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                          SAYFA 2: LOBİ
  // ═══════════════════════════════════════════════════════════════════════════

  Widget buildLobbyPage() {
    return Column(
      children: [
        AppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          title: const Text('LOBI', style: TextStyle(fontFamily: 'monospace')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: returnToMainMenu,
          ),
          actions: [
            if (isHostDevice)
              PopupMenuButton<int>(
                onSelected: selectMap,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0, child: Text('Ofis (Varsayilan)')),
                  const PopupMenuItem(value: 1, child: Text('Depo (Genis Alan)')),
                ],
                icon: const Icon(Icons.map, color: Colors.white),
              ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Harita: ${currentMapIndex == 1 ? 'Depo' : 'Ofis'}',
                  style: const TextStyle(color: Colors.grey, fontFamily: 'monospace')),
              const SizedBox(height: 10.0),
              Text('Oyuncular (${playerList.length}/$maximumPlayers):',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10.0),
              ...playerList.map((player) {
                final isMe = player.playerId == myPlayerId;
                final charName = player.characterId == 99 
                    ? 'Rastgele' 
                    : (player.characterId == -1 ? 'Secilmedi' : getCharacterName(player.characterId));
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(bottom: 6.0),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF1A0000) : const Color(0xFF111111),
                    border: Border.all(color: isMe ? const Color(0xFFB00000) : Colors.grey.shade800),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${player.playerName}${isMe ? ' (SEN)' : ''}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Karakter: $charName',
                                style: const TextStyle(color: Colors.grey, fontSize: 11.0)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 20.0),
              const Text('KARAKTER SECIMI',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10.0),
              
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  for (int i = 0; i < characterDefinitions.length; i++)
                    GestureDetector(
                      onTap: () => selectCharacter(i),
                      child: Container(
                        width: 70.0,
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          border: Border.all(
                            color: myCharacterId == i ? characterDefinitions[i].characterColor : Colors.grey.shade800,
                            width: myCharacterId == i ? 2.0 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Column(
                          children: [
                            buildAnimatronicBody(characterDefinitions[i].characterColor, 40.0, kind: i % 4),
                            const SizedBox(height: 4.0),
                            Text(characterDefinitions[i].characterName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: myCharacterId == i ? characterDefinitions[i].characterColor : Colors.grey,
                                  fontSize: 9.0,
                                  fontFamily: 'monospace',
                                )),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => selectCharacter(99),
                    child: Container(
                      width: 70.0,
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        border: Border.all(
                          color: myCharacterId == 99 ? const Color(0xFFB00000) : Colors.grey.shade800,
                          width: myCharacterId == 99 ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16.0),
                          const Icon(Icons.shuffle, color: Colors.grey, size: 24.0),
                          const SizedBox(height: 4.0),
                          Text('Rastgele',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: myCharacterId == 99 ? const Color(0xFFB00000) : Colors.grey,
                                fontSize: 9.0,
                                fontFamily: 'monospace',
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20.0),
              if (isHostDevice)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: playerList.length >= 2 ? startGameFromHost : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB00000),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text('OYUNU BASLAT', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                          SAYFA 3: OYUN EKRANI
  // ═══════════════════════════════════════════════════════════════════════════

  Widget buildGamePage() {
    return ValueListenableBuilder<int>(
      valueListenable: frameCounter,
      builder: (context, frame, child) {
        final shakeOffset = calculateShakeOffset(20.0);
        
        return Stack(
          children: [
            // Ana oyun alanı
            Transform.translate(
              offset: shakeOffset,
              child: buildGameContent(),
            ),
            
            // Vignette efekti
            if (qualitySettings.vignetteEffectEnabled) buildVignetteEffect(),
            
            // Noise efekti
            if (qualitySettings.noiseEffectEnabled)
              CustomPaint(
                painter: NoisePainter(frame, 0.8),
                size: Size.infinite,
              ),
            
            // UI overlay
            buildGameUI(),
          ],
        );
      },
    );
  }

  Widget buildGameContent() {
    if (currentGameMap == null) return const Center(child: CircularProgressIndicator());
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = min(constraints.maxWidth / 80.0, constraints.maxHeight / 60.0);
        
        return InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(100.0),
          minScale: 0.5,
          maxScale: 3.0,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 80.0,
                height: 60.0,
                child: Stack(
                  children: [
                    // Zemin deseni
                    const CustomPaint(painter: CheckerPainter(), size: Size(80.0, 60.0)),
                    
                    // Odalar
                    ...currentGameMap!.rooms.map((room) {
                      return Positioned(
                        left: room.roomRect.left + 40.0,
                        top: room.roomRect.top + 30.0,
                        width: room.roomRect.width,
                        height: room.roomRect.height,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            border: Border.all(color: const Color(0xFF333333)),
                          ),
                          child: Center(
                            child: Text(room.roomName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey, fontSize: 3.0)),
                          ),
                        ),
                      );
                    }).toList(),
                    
                    // Koridorlar (v2.0)
                    ...currentGameMap!.corridors.map((corridor) {
                      return Positioned(
                        left: corridor.corridorRect.left + 40.0,
                        top: corridor.corridorRect.top + 30.0,
                        width: corridor.corridorRect.width,
                        height: corridor.corridorRect.height,
                        child: Container(
                          decoration: BoxDecoration(
                            color: corridor.isIlluminated ? const Color(0xFF2A2A2A) : const Color(0xFF0D0D0D),
                            border: Border.all(
                              color: corridor.dangerLevel > 0.5 ? const Color(0xFFB00000) : const Color(0xFF444444),
                              width: 0.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    
                    // Ofis alanı
                    Positioned(
                      left: currentGameMap!.officeRect.left + 40.0,
                      top: currentGameMap!.officeRect.top + 30.0,
                      width: currentGameMap!.officeRect.width,
                      height: currentGameMap!.officeRect.height,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          border: Border.all(color: const Color(0xFFB00000), width: 0.5),
                        ),
                        child: const Center(
                          child: Text('OFIS',
                              style: TextStyle(color: Color(0xFFB00000), fontSize: 4.0, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    
                    // Kapılar
                    Positioned(
                      left: currentGameMap!.leftDoorPosition.dx + 40.0 - 2.0,
                      top: currentGameMap!.leftDoorPosition.dy + 30.0 - 3.0,
                      child: Container(
                        width: 4.0,
                        height: 6.0,
                        color: leftDoorClosed ? const Color(0xFF00FF00) : const Color(0xFFFF0000),
                      ),
                    ),
                    Positioned(
                      left: currentGameMap!.rightDoorPosition.dx + 40.0 - 2.0,
                      top: currentGameMap!.rightDoorPosition.dy + 30.0 - 3.0,
                      child: Container(
                        width: 4.0,
                        height: 6.0,
                        color: rightDoorClosed ? const Color(0xFF00FF00) : const Color(0xFFFF0000),
                      ),
                    ),
                    
                    // Vent
                    Positioned(
                      left: currentGameMap!.ventPosition.dx + 40.0 - 2.0,
                      top: currentGameMap!.ventPosition.dy + 30.0 - 2.0,
                      child: Container(
                        width: 4.0,
                        height: 4.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFF444444),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: Text('V', style: TextStyle(color: Colors.black, fontSize: 2.0))),
                      ),
                    ),
                    
                    // Oyuncular
                    ...getVisiblePlayers().map((visual) {
                      return Positioned(
                        left: visual.positionX + 40.0 - 3.0,
                        top: visual.positionY + 30.0 - 3.0,
                        child: Container(
                          width: 6.0,
                          height: 6.0,
                          decoration: BoxDecoration(
                            color: visual.characterColor,
                            shape: BoxShape.circle,
                            boxShadow: qualitySettings.glowEffectEnabled
                                ? [BoxShadow(color: visual.characterColor.withOpacity(0.5), blurRadius: 4.0)]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              visual.playerId == myPlayerId ? 'S' : (visual.playerRole == 0 ? 'G' : 'A'),
                              style: const TextStyle(color: Colors.black, fontSize: 3.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildGameUI() {
    return SafeArea(
      child: Column(
        children: [
          // Üst bilgi çubuğu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            color: const Color(0xCC000000),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(getGameClock(),
                          style: const TextStyle(
                              color: Color(0xFFB00000),
                              fontFamily: 'monospace',
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold)),
                      Text('Guc: ${officeEnergy.toStringAsFixed(0)}% | Kullanim: ${calculatePowerUsage()}/5',
                          style: const TextStyle(color: Colors.grey, fontSize: 10.0, fontFamily: 'monospace')),
                      if (currentGameMap != null)
                        Text(
                          'Sol Kapi Isi: ${currentGameMap!.leftDoorHeat.toStringAsFixed(0)} | '
                          'Sag KapI Isi: ${currentGameMap!.rightDoorHeat.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.orange, fontSize: 9.0, fontFamily: 'monospace'),
                        ),
                    ],
                  ),
                ),
                if (myRole == 0)
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildFnafButton('Sol Kapi', leftDoorClosed ? Colors.green : Colors.red,
                              () => performGuardAction('doorL')),
                          const SizedBox(width: 6.0),
                          buildFnafButton('Sag Kapi', rightDoorClosed ? Colors.green : Colors.red,
                              () => performGuardAction('doorR')),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildFnafButton('Fener', flashlightOn ? Colors.yellow : Colors.grey,
                              () => performGuardAction('flash')),
                          const SizedBox(width: 6.0),
                          buildFnafButton('Kamera', cameraSystemOn ? Colors.blue : Colors.grey,
                              () => performGuardAction('cam')),
                        ],
                      ),
                    ],
                  ),
                if (myRole == 1)
                  Column(
                    children: [
                      buildFnafButton(
                        getContextualAction().toUpperCase(),
                        const Color(0xFFB00000),
                        getContextualAction() != 'none' ? performMonsterInteraction : null,
                      ),
                      const SizedBox(height: 4.0),
                      buildFnafButton(
                        'YETENEK (${playerCooldownEnd > 0 ? playerCooldownEnd.toStringAsFixed(1) : 'HAZIR'})',
                        const Color(0xFFFFD54F),
                        playerCooldownEnd <= 0.0 ? performMonsterAbility : null,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Kamera görüntüsü (Guard ve kamera açıksa)
          if (myRole == 0 && cameraSystemOn)
            Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.all(8.0),
              color: const Color(0xCC000000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KAMERA ${cameraRoomIndex + 1}: ${currentGameMap?.rooms[cameraRoomIndex].roomName ?? ''}',
                      style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'monospace', fontSize: 12.0)),
                  Text(getCameraDetails(),
                      style: TextStyle(
                        color: cameraJamEndTime > gameTime ? const Color(0xFFFF0000) : const Color(0xFF00FF00),
                        fontFamily: 'monospace',
                        fontSize: 10.0,
                      )),
                  const SizedBox(height: 4.0),
                  Wrap(
                    spacing: 4.0,
                    children: [
                      for (int i = 0; i < (currentGameMap?.rooms.length ?? 0); i++)
                        GestureDetector(
                          onTap: () => setState(() => cameraRoomIndex = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            color: cameraRoomIndex == i ? const Color(0xFF00FF00) : const Color(0xFF333333),
                            child: Text('CAM${i + 1}',
                                style: TextStyle(
                                  color: cameraRoomIndex == i ? Colors.black : Colors.grey,
                                  fontSize: 9.0,
                                  fontFamily: 'monospace',
                                )),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          
          const Spacer(),
          
          // Joystick (sadece canavarlar için)
          if (myRole == 1)
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      joystickX = (details.localPosition.dx - 50.0) / 50.0;
                      joystickY = (details.localPosition.dy - 50.0) / 50.0;
                      final len = Offset(joystickX, joystickY).distance;
                      if (len > 1.0) {
                        joystickX /= len;
                        joystickY /= len;
                      }
                    });
                  },
                  onPanEnd: (_) => setState(() { joystickX = 0.0; joystickY = 0.0; }),
                  child: Container(
                    width: 100.0,
                    height: 100.0,
                    decoration: BoxDecoration(
                      color: const Color(0x44000000),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: Center(
                      child: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF666666),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFB00000)),
                        ),
                        transform: Matrix4.translationValues(joystickX * 30.0, joystickY * 30.0, 0.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Geri dönüş butonu
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: returnToMainMenu,
                backgroundColor: const Color(0xFFB00000),
                mini: true,
                child: const Icon(Icons.exit_to_app),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                          SAYFA 4: OYUN SONU
  // ═══════════════════════════════════════════════════════════════════════════

  Widget buildGameOverPage() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              winnerTeam == 1 ? 'GUVENLIK KAZANDI!' : 'ANIMATRONIKLER KAZANDI!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: winnerTeam == 1 ? const Color(0xFF00FF00) : const Color(0xFFB00000),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              endGameMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14.0),
            ),
            const SizedBox(height: 40.0),
            ElevatedButton(
              onPressed: returnToMainMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB00000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
              ),
              child: const Text('ANA MENUYE DON', style: TextStyle(fontFamily: 'monospace')),
            ),
          ],
        ),
      ),
    );
  }
}
