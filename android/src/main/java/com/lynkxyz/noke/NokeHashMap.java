package com.lynkxyz.noke;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;

import java.util.ArrayList;

public class NokeHashMap {
    private String name;
    private String macAddress;
    private String key;
    private String command;
    private ArrayList<String> commands;

    public NokeHashMap(ReadableMap data) {
        if(data == null) {
            return;
        }

        macAddress = data.hasKey("macAddress") ? data.getString("macAddress") : "";
        name = data.hasKey("name") ? data.getString("name") : "";
        key = data.hasKey("key") ? data.getString("key") : null;
        command = data.hasKey("command") ? data.getString("command") : null;
        ReadableArray readableArray = data.hasKey("commands") ? data.getArray("commands") : null;
        ArrayList<Object> commands = new ArrayList<>();

        if(readableArray != null) {
            commands = readableArray.toArrayList();
        }
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getMacAddress() {
        return macAddress;
    }

    public void setMacAddress(String macAddress) {
        this.macAddress = macAddress;
    }

    public String getKey() {
        return key;
    }

    public void setKey(String key) {
        this.key = key;
    }

    public String getCommand() {
        return command;
    }

    public void setCommand(String command) {
        this.command = command;
    }

    public ArrayList<String> getCommands() {
        return commands;
    }

    public void setCommands(ArrayList<String> commands) {
        this.commands = commands;
    }
}
